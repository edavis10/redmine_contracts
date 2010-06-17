require File.dirname(__FILE__) + '/../test_helper'

class DeliverableTest < ActiveSupport::TestCase
  should_belong_to :contract
  should_belong_to :manager
end
