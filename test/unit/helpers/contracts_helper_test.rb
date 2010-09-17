require 'test_helper'

class ContractsHelperTest < ActionView::TestCase
  context "#validate_period" do
    should "with a HourlyDeliverable should return nil" do
      assert_equal nil, validate_period(HourlyDeliverable.new, '2010-01')
    end
    
    should "with a FixedDeliverable should return nil" do
      assert_equal nil, validate_period(FixedDeliverable.new, '2010-01')
    end

    context "with a RetainerDeliverable" do
      should "return nil when there period is not within the Deliverable's date range" do
        retainer = RetainerDeliverable.new(:start_date => Date.new(2011,1,1),
                                           :end_date => Date.new(2012,1,1))

        assert_equal nil, validate_period(retainer, '2010-01')
      end
      
      should "return the period when it's within the Deliverable's date range" do
        retainer = RetainerDeliverable.new(:start_date => Date.new(2001,1,1),
                                           :end_date => Date.new(2003,1,1))

        assert_equal '2001-02', validate_period(retainer, '2001-02')
      end
    
    end
  end
  
end
