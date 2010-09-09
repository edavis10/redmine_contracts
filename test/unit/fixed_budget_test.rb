require File.dirname(__FILE__) + '/../test_helper'

class FixedBudgetTest < ActiveSupport::TestCase
  should_belong_to :deliverable

end
