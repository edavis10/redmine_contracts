require File.dirname(__FILE__) + '/../test_helper'

class RetainerDeliverableTest < ActiveSupport::TestCase
  should "be a subclass of HourlyDeliverable" do
    assert_equal HourlyDeliverable, RetainerDeliverable.superclass
  end

  context "#frequency" do
    should_allow_values_for(:frequency, nil, '', 'monthly', 'quarterly')
    should_not_allow_values_for(:frequency, 'anything', 'else', 'weekly')
  end

  # TODO: Question: Fit to calendar or based on N days?
  # Monthly => June-June or June 5th-July 5th
  # Quarterly => Jan-March 31 or Feb-May 31
  context "#current_period" do
    context "monthly frequency" do
      should "be a range of the current month"
    end

    context "quarterly frequency" do
      should "be a range of the current quarter"
    end
  end

  context "#start_of_current_period" do
    context "monthly frequency" do
      should "QUESTION: be the first day of the month or 30 days ago"
    end

    context "quarterly frequency" do
      should "QUESTION: be the first day of the quarter or 365/4 days ago"
    end
  end
  
  context "#end_of_current_period" do
    context "monthly frequency" do
      should "QUESTION: be the first day of the month or 30 days ago"
    end

    context "quarterly frequency" do
      should "QUESTION: be the first day of the quarter or 365/4 days ago"
    end
  end
end
