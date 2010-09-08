require File.dirname(__FILE__) + '/../test_helper'

class RetainerDeliverableTest < ActiveSupport::TestCase
  should "be a subclass of HourlyDeliverable" do
    assert_equal HourlyDeliverable, RetainerDeliverable.superclass
  end

  context "#months" do
    should "be an array of months the Deliverable is active in" do
      d = RetainerDeliverable.new(:start_date => Date.today.beginning_of_month,
                                  :end_date => 6.months.from_now)

      assert_equal 7, d.months.length # 6 months + current month
      d.months.each do |month|
        assert_kind_of Date, month
      end
    end

    should "return an empty array if start_date is missing" do
      d = RetainerDeliverable.new(:start_date => nil,
                                  :end_date => 6.months.from_now)
      assert_equal [], d.months
    end

    should "return an empty array if end_date is missing" do
      d = RetainerDeliverable.new(:start_date => Date.today.beginning_of_month,
                                  :end_date => nil)
      assert_equal [], d.months
    end

    should "return an empty array if the start_date and end_date are reversed" do
      d = RetainerDeliverable.new(:start_date => 6.months.from_now,
                                  :end_date => Date.today.beginning_of_month)
      assert_equal [], d.months
    end

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

  context "#labor_budget_spent_for_date" do
    context "with a empty period" do
      should "use all periods"
    end

    context "with a period out of the retainer range" do
      should "use all periods"
    end

    context "with a period in the retainer range" do
      should "filter the records"
    end
  end

  context "#labor_budget_total_for_date" do
    setup do
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31')
      @deliverable.labor_budgets << LaborBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.save!
    end
    
    context "with a empty period" do
      should "use all periods" do
        assert_equal 300.0, @deliverable.labor_budget_total_for_date(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records" do
        assert_equal 0, @deliverable.labor_budget_total_for_date(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.labor_budget_total_for_date('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 100.0, @deliverable.labor_budget_total_for_date(Date.new(2010,2,1))
      end
    end
  end

  # context "#overhead_spent_for_date"
  
  context "#overhead_budget_total_for_date" do
    setup do
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31')
      @deliverable.overhead_budgets << OverheadBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.save!
    end
    
    context "with a empty period" do
      should "use all periods" do
        assert_equal 300.0, @deliverable.overhead_budget_total_for_date(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records" do
        assert_equal 0, @deliverable.overhead_budget_total_for_date(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.overhead_budget_total_for_date('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 100.0, @deliverable.overhead_budget_total_for_date(Date.new(2010,2,1))
      end
    end
  end

  # context "#profit_left_for_date"
  # context "#profit_budget_for_date"
  # context "#total_spent_for_date"
  # context "#total_for_date"
end
