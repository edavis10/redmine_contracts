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

      assert_equal 400, deliverable.profit_budget
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
end
