require 'test_helper'

class DisabledContractsModuleTest < ActionController::IntegrationTest
  context "on a project with the Contracts module disabled" do
    setup do
      @project = Project.generate!
      @project.enabled_modules.find_by_name('contracts').destroy
      @project.reload
      assert !@project.module_enabled?(:contracts), "Contracts enabled on project"

      @user = User.generate_user_with_permission_to_manage_budget(:project => @project)
      login_as(@user.login, 'contracts')
    end

    should "not show the menu item" do
      visit_project(@project)
      
      assert_select "#main-menu" do
        assert_select 'a', :text => /contracts/i, :count => 0
      end
    end
    
    should "block access to list" do
      visit "/projects/#{@project.identifier}/contracts"
      assert_forbidden
    end

    should "block access to new" do
      visit "/projects/#{@project.identifier}/contracts/new"
      assert_forbidden
    end

    should "block access to show" do
      visit "/projects/#{@project.identifier}/contracts/1"
      assert_forbidden
    end

    should "block access to edit" do
      visit "/projects/#{@project.identifier}/contracts/1/edit"
      assert_forbidden
    end

  end

end
