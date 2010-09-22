require File.dirname(__FILE__) + '/../test_helper'

class FixedDeliverableTest < ActiveSupport::TestCase
  context "#profit_budget" do
    context "with no labor budget, no overhead budget" do
      should "equal the total" do
        assert_equal 1000, FixedDeliverable.generate(:total => 1_000).profit_budget
      end
    end

    should "be the total minus the sum of all of the budgets" do
      deliverable = FixedDeliverable.generate(:total => 1_000)
      LaborBudget.generate!(:deliverable => deliverable, :budget => 200)
      LaborBudget.generate!(:deliverable => deliverable, :budget => 200)
      OverheadBudget.generate!(:deliverable => deliverable, :budget => 200)
      FixedBudget.generate!(:deliverable => deliverable, :budget => '$100', :markup => '50%') # $50 markup

      assert_equal 400 - 150, deliverable.profit_budget
    end

    should "be 0 if there is no total" do
      assert_equal 0, FixedDeliverable.generate(:total => nil).profit_budget
    end
  end

  context "#total_spent" do
    should "equal the budgeted total" do
      assert_equal 1000, FixedDeliverable.generate(:total => 1_000).total_spent
    end
  end

  context "#profit_left" do
    should "be the total_spent minus the labor budget spent minus the overhead budget spent" do
      configure_overhead_plugin

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

      @deliverable_1 = FixedDeliverable.generate!(:total => 2000)
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
      
      assert_equal 875, @deliverable_1.profit_left

    end
  end
end
