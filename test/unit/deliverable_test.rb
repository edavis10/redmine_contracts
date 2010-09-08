require File.dirname(__FILE__) + '/../test_helper'

class DeliverableTest < ActiveSupport::TestCase
  should_belong_to :contract
  should_belong_to :manager
  should_have_many :labor_budgets
  should_have_many :overhead_budgets
  should_have_many :issues

  should_validate_presence_of :title
  should_validate_presence_of :type
  should_validate_presence_of :manager

  context "#total=" do
    should "strip dollar signs when writing" do
      d = Deliverable.new
      d.total = '$100.00'
      
      assert_equal 100.00, d.total.to_f
    end

    should "strip commas when writing" do
      d = Deliverable.new
      d.total = '20,100.00'
      
      assert_equal 20100.00, d.total.to_f
    end

    should "strip spaces when writing" do
      d = Deliverable.new
      d.total = '20 100.00'
      
      assert_equal 20100.00, d.total.to_f
    end
  end

  context "#labor_budget_spent_for_period" do
    should "use all periods"
  end
  
  context "#labor_budget_total_for_period" do
    should "use all periods"
  end
  
  context "#overhead_spent_for_period" do
    should "use all periods"
  end
  
  context "#overhead_budget_total_for_period" do
    should "use all periods"
  end
  
  context "#profit_left_for_period" do
    should "use all periods"
  end
  
  context "#profit_budget_for_period" do
    should "use all periods"
  end
  
  context "#total_spent_for_period" do
    should "use all periods"
  end
  
  context "#total_for_period" do
    should "use all periods"
  end
  

end
