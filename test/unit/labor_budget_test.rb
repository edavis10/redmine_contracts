require File.dirname(__FILE__) + '/../test_helper'

class LaborBudgetTest < ActiveSupport::TestCase
  should_belong_to :deliverable
  should_belong_to :time_entry_activity

  should_validate_presence_of :time_entry_activity_id

  context "#budget=" do
    should "strip dollar signs when writing" do
      e = LaborBudget.new
      e.budget = '$100.00'
      
      assert_equal 100.00, e.budget.to_f
    end

    should "strip commas when writing" do
      e = LaborBudget.new
      e.budget = '20,100.00'
      
      assert_equal 20100.00, e.budget.to_f
    end

    should "strip spaces when writing" do
      e = LaborBudget.new
      e.budget = '20 100.00'
      
      assert_equal 20100.00, e.budget.to_f
    end
  end

end
