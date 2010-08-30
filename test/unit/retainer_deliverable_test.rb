require File.dirname(__FILE__) + '/../test_helper'

class RetainerDeliverableTest < ActiveSupport::TestCase
  should "be a subclass of HourlyDeliverable" do
    assert_equal HourlyDeliverable, RetainerDeliverable.superclass
  end

  context "#frequency" do
    should_allow_values_for(:frequency, nil, '', 'monthly', 'quarterly')
    should_not_allow_values_for(:frequency, 'anything', 'else', 'weekly')
  end

  context "#create_budgets_for_periods" do
    setup do
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-10',
                                                   :end_date => '2010-10-10')
      LaborBudget.generate!(:deliverable => @deliverable)
      OverheadBudget.generate!(:deliverable => @deliverable)
      OverheadBudget.generate!(:deliverable => @deliverable)
    end

    should "create a dated labor budget for each month" do
      assert_equal 1, @deliverable.labor_budgets.count

      @deliverable.reload.create_budgets_for_periods

      assert_equal 10, @deliverable.labor_budgets.count
      labor_budgets = @deliverable.labor_budgets
      labor_budgets.each do |budget|
        assert_equal 2010, budget.year
      end

      (1..10).each do |month_number|
        assert_equal 1, labor_budgets.select {|b| b.month == month_number}.length
      end
      
    end

    should "create a dated overhead budget for each month" do
      assert_equal 2, @deliverable.overhead_budgets.count

      @deliverable.reload.create_budgets_for_periods

      assert_equal 20, @deliverable.overhead_budgets.count
      overhead_budgets = @deliverable.overhead_budgets
      overhead_budgets.each do |budget|
        assert_equal 2010, budget.year
      end

      (1..10).each do |month_number|
        assert_equal 2, overhead_budgets.select {|b| b.month == month_number}.length
      end
      
    end
  end
  
end
