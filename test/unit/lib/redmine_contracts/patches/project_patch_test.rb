require File.dirname(__FILE__) + '/../../../../test_helper'

class RedmineContracts::Patches::ProjectTest < ActionController::TestCase

  context "Project" do
    subject { Project.new }
    should_have_many :contracts
    should_have_many :deliverables
  end
end
