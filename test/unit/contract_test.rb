require File.dirname(__FILE__) + '/../test_helper'

class ContractTest < ActiveSupport::TestCase
  should_belong_to :account_executive
  should_belong_to :project
end
