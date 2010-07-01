require File.dirname(__FILE__) + '/../test_helper'

class DeliverableTest < ActiveSupport::TestCase
  should_belong_to :contract
  should_belong_to :manager

  should_validate_presence_of :title
  should_validate_presence_of :type
  should_validate_presence_of :manager
end
