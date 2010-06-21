require 'test_helper'

class ContractsNewTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
  end

  should "allow any user to open the new contracts form" do
    visit_contracts_for_project(@project)
    click_link 'New Contract'
    assert_response :success

    assert_select "form#new_contract"
  end

end
