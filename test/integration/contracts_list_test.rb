require 'test_helper'

class ContractsListTest < ActionController::IntegrationTest
  def setup
    @project = Project.generate!
    @contract = Contract.generate!(:project => @project)
  end

  should "allow any user to list the contracts on a project" do
    visit_project(@project)
    click_link "Contracts"

    assert_response :success
    assert_template 'contracts/index'
  end

end
