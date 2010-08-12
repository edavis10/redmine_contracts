require 'test_helper'

class BudgetPluginMigrationTest < ActionController::IntegrationTest
  def setup
    configure_overhead_plugin
  end

  def load_test_fixture
    File.read(File.expand_path(File.dirname(__FILE__)) + "/../fixtures/budget_plugin_migration/budget.yml")
  end

  context "migrate" do
    setup do
      @data = load_test_fixture
      @project_one = Project.generate!
      @project_two = Project.generate!
      # Stub out the Project finders because we need to match the ids but can't
      # be sure what ids object_daddy will give us
      Project.stubs(:find_by_id).with(1).returns(@project_one)
      Project.stubs(:find_by_id).with(2).returns(@project_one)

      @manager = User.generate!
      @role = Role.generate!
      User.add_to_project(@manager, @project_one, @role)
      User.add_to_project(@manager, @project_two, @role)

    end

    should "load a YAML dump of the old budget data" do
      RedmineContracts::BudgetPluginMigration.migrate(@data)

      assert_equal YAML.load(@data), RedmineContracts::BudgetPluginMigration.data
    end
    
    should "create a new Deliverable for each old Deliverable" do

      assert_difference("Deliverable.count", 3) do
        assert_difference("HourlyDeliverable.count", 0) do
          assert_difference("FixedDeliverable.count", 3) do
            RedmineContracts::BudgetPluginMigration.migrate(@data)
          end
        end
      end

    end
    
    should "create a new Contract for each project that had an old deliverable" do
      assert_difference("Contract.count", 2) do
        RedmineContracts::BudgetPluginMigration.migrate(@data)
      end

      assert_equal 1, @project_one.reload.contracts.first.deliverables.count
      assert_equal 2, @project_two.reload.contracts.first.deliverables.count
    end

    context "on new Contracts" do
      should "default the contract billable rate to $150" do
        RedmineContracts::BudgetPluginMigration.migrate(@data)

        assert_equal 150, @project_one.reload.contracts.first.billable_rate
        assert_equal 150, @project_two.reload.contracts.first.billable_rate
      end

      should "allow overriding the contract billable rate" do
        RedmineContracts::BudgetPluginMigration.migrate(@data, :contract_rate => '100.50')

        assert_equal 100.5, @project_one.reload.contracts.first.billable_rate
        assert_equal 100.5, @project_two.reload.contracts.first.billable_rate
      end
    end

    should "enable the contracts plugin for each project with a contract" do
      @no_deliverables = Project.generate!(:enabled_modules => [])
      RedmineContracts::BudgetPluginMigration.migrate(@data)

      assert @project_one.reload.module_enabled?(:contracts)
      assert @project_two.reload.module_enabled?(:contracts)
      assert !@no_deliverables.reload.module_enabled?(:contracts)
    end

    should "pick the first project member for the deliverable manager" do
      RedmineContracts::BudgetPluginMigration.migrate(@data)

      assert_equal [@manager, @manager, @manager], Deliverable.all.collect(&:manager)
    end

    should "create a new Overhead Budget record for any overhead" do
      assert_difference("OverheadBudget.count", 5) do
        RedmineContracts::BudgetPluginMigration.migrate(@data)
      end

      d = Deliverable.find_by_title("Deliverable One")
      assert_equal 2, d.overhead_budgets.count
      assert_equal 400, d.overhead_budget_total

      overhead = d.overhead_budgets.first
      assert overhead
      assert_equal 200, overhead.budget
      assert_equal 0, overhead.hours
    end

    should "create a new Overhead Budget record for any overhead percent" do
      assert_difference("OverheadBudget.count", 5) do
        RedmineContracts::BudgetPluginMigration.migrate(@data)
      end

      d = Deliverable.find_by_title("Deliverable 2")
      assert_equal 2, d.overhead_budgets.count

      overhead = d.overhead_budgets.first
      assert overhead
      assert_equal 12 * 25 * 1.5, overhead.budget
      assert_equal 0, overhead.hours

    end

    should "create a new Overhead Budget record for any materials" do
      assert_difference("OverheadBudget.count", 5) do
        RedmineContracts::BudgetPluginMigration.migrate(@data)
      end

      d = Deliverable.find_by_title("Deliverable One")
      assert_equal 2, d.overhead_budgets.count
      assert_equal 400, d.overhead_budget_total

      materials = d.overhead_budgets.last
      assert materials
      assert_equal 200, materials.budget
      assert_equal 0, materials.hours
    end

    should "create a new Overhead Budget record for any materials percent" do
      assert_difference("OverheadBudget.count", 5) do
        RedmineContracts::BudgetPluginMigration.migrate(@data)
      end

      d = Deliverable.find_by_title("Deliverable 2")
      assert_equal 2, d.overhead_budgets.count
      materials = d.overhead_budgets.last
      assert materials
      assert_equal 12 * 25 * 0.1, materials.budget
      assert_equal 0, materials.hours

    end

    should "append the YAML dump of the old object to the notes" do
      RedmineContracts::BudgetPluginMigration.migrate(@data)
      d = Deliverable.find_by_title("Deliverable One")

      assert_match /Converted data/, d.notes
      assert_match /"profit"=>200.0/, d.notes
    end

    context "converting Fixed Deliverables" do
      should "convert the budget field to total" do
        RedmineContracts::BudgetPluginMigration.migrate(@data)

        d = FixedDeliverable.find_by_title("Version 1.0")
        assert_equal 93_000, d.total
      end
    end

    context "converting Hourly Deliverables" do
      should "convert over into Fixed Deliverables" do
        assert_difference("FixedDeliverable.count",3) do
          RedmineContracts::BudgetPluginMigration.migrate(@data)
        end
      end

      should "convert the old 'budget' field into the total" do
        RedmineContracts::BudgetPluginMigration.migrate(@data)

        assert_equal 5600, FixedDeliverable.find_by_title("Deliverable One").total
        assert_equal 900, FixedDeliverable.find_by_title("Deliverable 2").total
      end
      
      should "create a new Labor Budget" do
        assert_difference("LaborBudget.count", 2) do
          RedmineContracts::BudgetPluginMigration.migrate(@data)
        end

        d1 = Deliverable.find_by_title("Deliverable One")
        assert_equal 1, d1.labor_budgets.count
        assert_equal 100.0 * 50.0, d1.labor_budget_total

        labor1 = d1.labor_budgets.first
        assert labor1
        assert_equal 5000, labor1.budget
        assert_equal 100, labor1.hours

        d2 = Deliverable.find_by_title("Deliverable 2")
        assert_equal 1, d2.labor_budgets.count
        assert_equal 12 * 25, d2.labor_budget_total

        labor1 = d2.labor_budgets.first
        assert labor1
        assert_equal 300, labor1.budget
        assert_equal 12, labor1.hours
        
      end
    end

    context "converting issue ids" do
      setup do
        @issue1 = Issue.generate_for_project!(@project_two, :deliverable_id => 2)
        @issue2 = Issue.generate_for_project!(@project_two, :deliverable_id => 4)
        @issue3 = Issue.generate_for_project!(@project_one, :deliverable_id => 1)
        
      end
      
      should "keep the same Deliverable assigned" do
        RedmineContracts::BudgetPluginMigration.migrate(@data)

        assert_equal "Deliverable 2", @issue1.reload.deliverable.title
        assert_equal "Version 1.0", @issue2.reload.deliverable.title
      end
      
      should "handle primary key differences between the old and new Deliverables" do
        RedmineContracts::BudgetPluginMigration.migrate(@data)

        # The "third" deliverable has an id of 4
        assert_equal "Deliverable 2", @issue1.reload.deliverable.title
        assert_equal "Version 1.0", @issue2.reload.deliverable.title
        assert_equal "Deliverable One", @issue3.reload.deliverable.title
      end
    end

  end
end

