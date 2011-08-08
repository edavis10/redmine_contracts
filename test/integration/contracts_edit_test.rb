require 'test_helper'

class ContractsEditTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @account_executive = User.generate!
    @role = Role.generate!
    User.add_to_project(@account_executive, @project, @role)
    @contract = Contract.generate!(:project => @project, :name => 'A Contract', :account_executive => @account_executive)
    @user = User.generate_user_with_permission_to_manage_budget(:project => @project)
    
    login_as(@user.login, 'contracts')
  end

  should "block anonymous users from editing the contract" do
    logout
    visit "/projects/#{@project.identifier}/contracts/#{@contract.id}/edit"

    assert_requires_login
  end
  
  should "block unauthorized users from editing the contract" do
    logout

    @user = User.generate!(:password => 'test', :password_confirmation => 'test')
    login_as(@user.login, 'test')
    
    visit "/projects/#{@project.identifier}/contracts/#{@contract.id}/edit"

    assert_forbidden
  end

  should "allow authorized users to edit the contract" do
    visit_contracts_for_project(@project)
    click_link @contract.id
    assert_response :success

    click_link 'Update'
    assert_response :success
    assert_template 'contracts/edit'

    assert_select "h2", :text => /#{@contract.name}/
    assert_select "form#edit_contract_#{@contract.id}.contract" do
      assert_select "input[value=?]", /#{@contract.name}/
      assert_select "select#contract_payment_term_id"
    end

    fill_in "Name", :with => 'An updated name'
    select "Locked", :from => "Status"
    click_button "Save Contract"

    assert_response :success
    assert_template 'contracts/show'

    assert_equal "An updated name", @contract.reload.name
    assert_equal "locked", @contract.reload.status
  end
end
