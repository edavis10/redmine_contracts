require File.dirname(__FILE__) + '/../../../../test_helper'

class RedmineContracts::Patches::IssueTest < ActionController::TestCase

  context "Issue" do
    subject { Issue.new }
    should_belong_to :deliverable
  end
end
