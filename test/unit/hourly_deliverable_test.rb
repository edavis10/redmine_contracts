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
end
