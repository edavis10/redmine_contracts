require 'test_helper'

class DeliverablesDeleteTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project, :name => 'A Contract')
    @manager = User.generate!
    @deliverable = FixedDeliverable.generate!(:contract => @contract, :manager => @manager)
    @user = User.generate_user_with_permission_to_manage_budget(:project => @project)
    
    login_as(@user.login, 'contracts')
  end

  should "block anonymous users from deleting the deliverable" do
    logout
    delete "/projects/#{@project.identifier}/contracts/#{@contract.id}/deliverables/#{@deliverable.id}"
    follow_redirect!
    
    assert_requires_login
  end
  
  should "block unauthorized users from deleting the deliverable" do
    logout

    @user = User.generate!(:password => 'test', :password_confirmation => 'test')
    login_as(@user.login, 'test')
    
    delete "/projects/#{@project.identifier}/contracts/#{@contract.id}/deliverables/#{@deliverable.id}"

    assert_forbidden
  end

  should "allow authorized users to delete the deliverable" do
    visit_contract_page(@contract)

    click_link_within "#deliverable_details_#{@deliverable.id}", 'Delete'
    assert_response :success
    assert_template 'contracts/show'

    assert_nil Deliverable.find_by_id(@deliverable.id), "Deliverable not deleted"
  end
end
