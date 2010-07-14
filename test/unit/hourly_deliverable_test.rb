require File.dirname(__FILE__) + '/../test_helper'

class HourlyDeliverableTest < ActiveSupport::TestCase
  context "#total" do
    should "be 0 when not assigned to a contract" do
      assert_equal 0, HourlyDeliverable.new.total
    end
    
    should "be 0 with no billable rate set on the Contract" do
      contract = Contract.generate!(:billable_rate => nil)
      d = HourlyDeliverable.generate!(:contract => contract)

      assert_equal 0, d.total
    end

    should "be 0 with no budgets" do
      contract = Contract.generate!(:billable_rate => 100.0)
      d = HourlyDeliverable.generate!(:contract => contract)

      assert_equal 0, d.total
    end
    
    should "multiply the total number of labor budget hours by the contract billable rate" do
      contract = Contract.generate!(:billable_rate => 100.0)
      d = HourlyDeliverable.generate!(:contract => contract)
      d.labor_budgets << LaborBudget.generate!(:hours => 10)
      d.overhead_budgets << OverheadBudget.generate!(:hours => 20)

      assert_equal 100.0 * 10, d.total
    end
  end

  context "#total_spent" do
    should "be equal to the number of hours used multipled by the contract rate" do
      configure_overhead_plugin

      contract = Contract.generate!(:billable_rate => 150.0)
      @project = Project.generate!
      @developer = User.generate!
      @role = Role.generate!
      User.add_to_project(@developer, @project, @role)

      d = HourlyDeliverable.generate!(:contract => contract)
      d.issues << @issue1 = Issue.generate_for_project!(@project)
      TimeEntry.generate!(:hours => 15, :issue => @issue1, :project => @project,
                          :activity => @billable_activity,
                          :user => @developer)

      assert_equal 2250, d.total_spent
    end
  end
  
  context "#total=" do
    should "not write any attributes" do
      d = HourlyDeliverable.new
      d.total = '$100.00'
      
      assert_equal nil, d.read_attribute(:total)
    end
  end

  context "clear_total" do
    should "clear any total attributes" do
      d = HourlyDeliverable.new
      d.write_attribute(:total, 100.00)
      d.clear_total
      
      assert_equal nil, d.read_attribute(:total)
      
    end
  end

  context "#profit_budget" do
    setup do
      @contract = Contract.generate!(:billable_rate => 150.0)
      @deliverable = HourlyDeliverable.generate!(:contract => @contract)
    end
    
    context "with no labor budget, no overhead budget" do
      should "be 0 (no hours available to bill)" do
        assert_equal 0, @deliverable.profit_budget
      end
    end

    should "be the total minus the sum of all of the budgets' amounts" do
      LaborBudget.generate!(:deliverable => @deliverable, :hours => 5, :budget => 250)
      LaborBudget.generate!(:deliverable => @deliverable, :hours => 5, :budget => 250)
      OverheadBudget.generate!(:deliverable => @deliverable, :hours => 3, :budget => 225)

      assert_equal 1500, @deliverable.total
      assert_equal 1500 - (225 + 250 + 250), @deliverable.profit_budget
    end
  end

  context "#profit_left" do
    should "be equal to the total to bill (total_spent) minus the labor budget spent minus the overhead spent" do
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

      @deliverable_1 = HourlyDeliverable.generate!(:contract => contract)
      @deliverable_1.issues << @issue1 = Issue.generate_for_project!(@project)
      TimeEntry.generate!(:hours => 15, :issue => @issue1, :project => @project,
                          :activity => @billable_activity,
                          :user => @developer)
      TimeEntry.generate!(:hours => 4, :issue => @issue1, :project => @project,
                          :activity => @non_billable_activity,
                          :user => @manager)

      # Check intermediate values
      assert_equal 825, @deliverable_1.labor_budget_spent
      assert_equal 300, @deliverable_1.overhead_spent
      
      assert_equal 1125, @deliverable_1.profit_left
    end
  end

end
