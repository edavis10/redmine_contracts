require File.dirname(__FILE__) + '/../test_helper'

class RetainerDeliverableTest < ActiveSupport::TestCase
  should "be a subclass of HourlyDeliverable" do
    assert_equal HourlyDeliverable, RetainerDeliverable.superclass
  end
end
