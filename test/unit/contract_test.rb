require File.dirname(__FILE__) + '/../test_helper'

class ContractTest < ActiveSupport::TestCase
  should_belong_to :account_executive
  should_belong_to :project

  should_validate_presence_of :name
  should_validate_presence_of :account_executive
  should_validate_presence_of :project
  should_validate_presence_of :start_date
  should_validate_presence_of :end_date
  should_validate_presence_of :executed

  should_not_allow_mass_assignment_of :project_id, :project, :discount_type
  
  should_allow_values_for :discount_type, "$", "%", nil, ''
  should_not_allow_values_for :discount_type, ["amount", "percent", "bar"]

  context "start_date" do
    should "be before end_date"
  end

  should "QUESTION: name be unique"
  should "default executed to false"
  
end
