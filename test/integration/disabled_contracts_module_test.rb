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
      visit '/'
      assert_response :success

      click_link 'Projects'
      assert_response :success

      click_link @project.name
      assert_response :success

      assert_select "#main-menu" do
        assert_select 'a', :text => /contracts/i, :count => 0
      end

      visit "/projects/#{@project.identifier}/contracts"
      assert_response :forbidden
      assert_template 'common/403'
    end
  end

end
