require File.dirname(__FILE__) + '/../test_helper'

class HourlyDeliverableTest < ActiveSupport::TestCase
  context "#total=" do
    should "not write any attributes" do
      d = HourlyDeliverable.new
      d.total = '$100.00'
      
      assert_equal nil, d.total
    end
  end

  context "clear_total" do
    should "clear any total attributes" do
      d = HourlyDeliverable.new
      d.write_attribute(:total, 100.00)
      d.clear_total
      
      assert_equal nil, d.total
      
    end
  end
end
