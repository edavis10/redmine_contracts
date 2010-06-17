require 'test_helper'

class DisabledContractsModuleTest < ActionController::IntegrationTest
  def setup
    @user = User.generate!(:login => 'existing', :password => 'existing', :password_confirmation => 'existing', :admin => true)
    login_as
  end

  context "on a project with the Contracts module disabled" do
    setup do
      @project = Project.generate!
      @project.enabled_modules.find_by_name('contracts').destroy
      @project.reload
      assert !@project.module_enabled?(:contracts), "Contracts enabled on project"
    end
    
    should "block access to list" do
      visit_project(@project)
      
      assert_select "#main-menu" do
        assert_select 'a', :text => /contracts/i, :count => 0
      end

      visit "/projects/#{@project.identifier}/contracts"
      assert_forbidden
    end
  end

end
