require 'test_helper'

class ContractsDeleteTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project, :name => 'A Contract')
  end

  should "allow admins to delete the contract" do
    @user = User.generate!(:login => 'admin', :password => 'existing', :password_confirmation => 'existing', :admin => true)
    login_as('admin', 'existing')
    
    visit_contracts_for_project(@project)
    click_link @contract.id
    assert_response :success

    click_link 'Update'
    assert_response :success
    assert_template 'contracts/edit'

    assert_select "a[href=?]", contract_path(@project, @contract), :text => /Delete/
    click_link 'Delete'
    assert_response :success
    assert_template 'contracts/index'

    assert_nil Contract.find_by_id(@contract.id), "Contract not deleted"
  end

  should "not allow non-admins to delete the contract" do
    visit_contracts_for_project(@project)
    click_link @contract.id
    assert_response :success

    click_link 'Update'
    assert_response :success
    assert_template 'contracts/edit'

    assert_select "a", :text => /Delete/, :count => 0
    delete contract_path(@project, @contract)
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_template 'account/login' # Prompt for login

    assert Contract.find_by_id(@contract.id), "Contract deleted"
  end
end
