require File.dirname(__FILE__) + '/../test_helper'

class ContractTest < ActiveSupport::TestCase
  should_belong_to :account_executive
  should_belong_to :project
  should_have_many :deliverables

  should_validate_presence_of :name
  should_validate_presence_of :account_executive
  should_validate_presence_of :project
  should_validate_presence_of :start_date
  should_validate_presence_of :end_date

  should_not_allow_mass_assignment_of :project_id, :project, :discount_type
  
  should_allow_values_for :discount_type, "$", "%", nil, ''
  should_not_allow_values_for :discount_type, ["amount", "percent", "bar"]

  context "end_date" do
    should "be after start_date" do
      @contract = Contract.new(:start_date => Date.today, :end_date => Date.yesterday)

      assert @contract.invalid?
      assert_equal "must be greater than start date", @contract.errors.on(:end_date)
    end
  end

  should "QUESTION: name be unique"

  should "default executed to false" do
    @contract = Contract.new
    
    assert_equal false, @contract.executed
  end

  context "#labor_budget" do
    should "sum all of the labor budgets of the Deliverables" do
      contract = Contract.generate!
      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!
      LaborBudget.generate!(:deliverable => @deliverable_1, :budget => 100)
      contract.deliverables << @deliverable_2 = FixedDeliverable.generate!
      LaborBudget.generate!(:deliverable => @deliverable_2, :budget => 100)

      assert_equal 200, contract.labor_budget
    end
  end

  context "#labor_spent" do
    setup do
      configure_overhead_plugin
    end

    should "sum all of the labor spent on the Deliverables" do
      @project = Project.generate!
      @manager = User.generate!
      @role = Role.generate!
      User.add_to_project(@manager, @project, @role)
      @rate = Rate.generate!(:project => @project,
                             :user => @manager,
                             :date_in_effect => Date.yesterday,
                             :amount => 100)

      contract = Contract.generate!
      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!
      @deliverable_1.issues << @issue1 = Issue.generate_for_project!(@project)
      TimeEntry.generate!(:hours => 5, :issue => @issue1, :project => @project,
                          :activity => @billable_activity,
                          :user => @manager)

      contract.deliverables << @deliverable_2 = HourlyDeliverable.generate!
      @deliverable_2.issues << @issue2 = Issue.generate_for_project!(@project)
      TimeEntry.generate!(:hours => 20, :issue => @issue2, :project => @project,
                          :activity => @billable_activity,
                          :user => @manager)

      assert_equal 2500, contract.labor_spent

    end
  end

  context "#overhead_budget" do
    should "sum all of the overhead budgets of the Deliverables" do
      contract = Contract.generate!
      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!
      OverheadBudget.generate!(:deliverable => @deliverable_1, :budget => 100)
      contract.deliverables << @deliverable_2 = FixedDeliverable.generate!
      OverheadBudget.generate!(:deliverable => @deliverable_2, :budget => 100)

      assert_equal 200, contract.overhead_budget
    end
  end

  context "#overhead_spent" do
    setup do
      configure_overhead_plugin
    end

    should "sum all of the overhead spent on the Deliverables" do
      @project = Project.generate!
      @manager = User.generate!
      @role = Role.generate!
      User.add_to_project(@manager, @project, @role)
      @rate = Rate.generate!(:project => @project,
                             :user => @manager,
                             :date_in_effect => Date.yesterday,
                             :amount => 100)

      contract = Contract.generate!
      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!
      @deliverable_1.issues << @issue1 = Issue.generate_for_project!(@project)
      TimeEntry.generate!(:hours => 10, :issue => @issue1, :project => @project,
                          :activity => @non_billable_activity,
                          :user => @manager)

      contract.deliverables << @deliverable_2 = HourlyDeliverable.generate!
      @deliverable_2.issues << @issue2 = Issue.generate_for_project!(@project)
      TimeEntry.generate!(:hours => 10, :issue => @issue2, :project => @project,
                          :activity => @non_billable_activity,
                          :user => @manager)

      assert_equal 2000, contract.overhead_spent

    end
  end

  context "#estimated_hour_budget" do
    should "sum all of the labor and overhead budgets of the Deliverables" do
      contract = Contract.generate!
      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!
      LaborBudget.generate!(:deliverable => @deliverable_1, :hours => 50)
      contract.deliverables << @deliverable_2 = HourlyDeliverable.generate!
      OverheadBudget.generate!(:deliverable => @deliverable_2, :hours => 60)

      assert_equal 110, contract.estimated_hour_budget
    end
  end

  context "#estimated_hour_spent" do
    should "sum all of the hours spent on the Deliverables" do
      @project = Project.generate!
      contract = Contract.generate!
      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!
      @deliverable_1.issues << @issue1 = Issue.generate_for_project!(@project)
      @deliverable_1.issues << @issue2 = Issue.generate_for_project!(@project)
      TimeEntry.generate!(:hours => 10, :issue => @issue1, :project => @project)
      TimeEntry.generate!(:hours => 10, :issue => @issue2, :project => @project)

      contract.deliverables << @deliverable_2 = HourlyDeliverable.generate!
      @deliverable_2.issues << @issue3 = Issue.generate_for_project!(@project)
      @deliverable_2.issues << @issue4 = Issue.generate_for_project!(@project)
      TimeEntry.generate!(:hours => 10, :issue => @issue3, :project => @project)
      TimeEntry.generate!(:hours => 10, :issue => @issue4, :project => @project)

      assert_equal 40, contract.estimated_hour_spent
    end
  end

  context "#total_budget" do
    should "sum all of the totals of the Deliverables" do
      contract = Contract.generate!(:billable_rate => 100.0)
      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!(:total => 10_000)
      contract.deliverables << @deliverable_2 = HourlyDeliverable.generate!
      LaborBudget.generate!(:deliverable => @deliverable_2, :hours => 10)
      OverheadBudget.generate!(:deliverable => @deliverable_2, :hours => 20)

      assert_equal 10_000 + (10 * 100), contract.total_budget
    end
  end

  context "#profit_budget" do
    should "sum all of the profit budgets of the Deliverables" do
      contract = Contract.generate!(:billable_rate => 100.0)

      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!(:total => 10_000)
      LaborBudget.generate!(:deliverable => @deliverable_1, :budget => 2000)
      OverheadBudget.generate!(:deliverable => @deliverable_1, :budget => 2000)
      
      contract.deliverables << @deliverable_2 = HourlyDeliverable.generate!
      LaborBudget.generate!(:deliverable => @deliverable_2, :hours => 10)
      OverheadBudget.generate!(:deliverable => @deliverable_2, :hours => 20)

      assert_equal 10_000 - 4000, @deliverable_1.profit_budget
      assert_equal (10 * 100.0) - 0, @deliverable_2.profit_budget
      assert_equal 7000, contract.profit_budget
      
    end
  end

  context "#total_spent" do
    should "sum all of the total spents on the Deliverables" do
      configure_overhead_plugin

      contract = Contract.generate!(:billable_rate => 150.0)

      @project = Project.generate!
      @developer = User.generate!
      @role = Role.generate!
      User.add_to_project(@developer, @project, @role)

      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!(:total => 10_000)
      contract.deliverables << @deliverable_2 = HourlyDeliverable.generate!(:contract => contract)
      @deliverable_2.issues << @issue1 = Issue.generate_for_project!(@project)
      TimeEntry.generate!(:hours => 15, :issue => @issue1, :project => @project,
                          :activity => @billable_activity,
                          :user => @developer)

      assert_equal 10_000, @deliverable_1.total_spent
      assert_equal 2250, @deliverable_2.total_spent
      assert_equal 12_250, contract.total_spent
    end
  end

  context "#profit_left" do
    should "sum all of the profit left on all of the Deliverables" do
      configure_overhead_plugin

      contract = Contract.generate!(:billable_rate => 150.0)

      @project = Project.generate!
      @developer = User.generate!
      @manager = User.generate!
      @role = Role.generate!
      User.add_to_project(@developer, @project, @role)
      User.add_to_project(@manager, @project, @role)
      @rate = Rate.generate!(:project => @project,
                             :user => @developer,
                             :date_in_effect => Date.yesterday,
                             :amount => 55)
      @rate = Rate.generate!(:project => @project,
                             :user => @manager,
                             :date_in_effect => Date.yesterday,
                             :amount => 75)

      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!(:total => 2000)
      @deliverable_1.issues << @issue1 = Issue.generate_for_project!(@project)
      TimeEntry.generate!(:hours => 15, :issue => @issue1, :project => @project,
                          :activity => @billable_activity,
                          :user => @developer)
      TimeEntry.generate!(:hours => 4, :issue => @issue1, :project => @project,
                          :activity => @non_billable_activity,
                          :user => @manager)

      contract.deliverables << @deliverable_2 = HourlyDeliverable.generate!(:contract => contract)
      @deliverable_2.issues << @issue2 = Issue.generate_for_project!(@project)
      TimeEntry.generate!(:hours => 15, :issue => @issue2, :project => @project,
                          :activity => @billable_activity,
                          :user => @developer)
      TimeEntry.generate!(:hours => 4, :issue => @issue2, :project => @project,
                          :activity => @non_billable_activity,
                          :user => @manager)

      assert_equal 875, @deliverable_1.profit_left
      assert_equal 1125, @deliverable_2.profit_left
      assert_equal 2000, contract.profit_left
    end

  end
end
