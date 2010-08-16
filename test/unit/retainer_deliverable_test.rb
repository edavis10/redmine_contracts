require File.dirname(__FILE__) + '/../test_helper'

class RetainerDeliverableTest < ActiveSupport::TestCase
  should "be a subclass of HourlyDeliverable" do
    assert_equal HourlyDeliverable, RetainerDeliverable.superclass
  end

  context "#frequency" do
    should_allow_values_for(:frequency, nil, '', 'monthly', 'quarterly')
    should_not_allow_values_for(:frequency, 'anything', 'else', 'weekly')
  end
end
