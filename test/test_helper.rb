# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

require "webrat"

Webrat.configure do |config|
  config.mode = :rails
end

def User.add_to_project(user, project, role)
  Member.generate!(:principal => user, :project => project, :roles => [role])
end

def User.generate_user_with_permission_to_manage_budget(options={})
  project = options[:project]
  
  user = User.generate!(:password => 'contracts', :password_confirmation => 'contracts')
  role = Role.generate!(:permissions => [:view_issues, :edit_issues, :add_issues, :manage_budget])
  User.add_to_project(user, project, role)
  user
end


module IntegrationTestHelper
  def login_as(user="existing", password="existing")
    visit "/login"
    fill_in 'Login', :with => user
    fill_in 'Password', :with => password
    click_button 'login'
    assert_response :success
    assert User.current.logged?
  end

  def logout
    visit '/logout'
    assert_response :success
    assert !User.current.logged?
  end
  
  def visit_project(project)
    visit '/'
    assert_response :success

    click_link 'Projects'
    assert_response :success

    click_link project.name
    assert_response :success
  end

  def visit_contracts_for_project(project)
    visit_project(project)
    click_link "Contracts"

    assert_response :success
    assert_template 'contracts/index'
  end

  def visit_contract_page(contract)
    visit_contracts_for_project(contract.project)
    click_link @contract.id
    
    assert_response :success
    assert_template 'contracts/show'
  end

  def visit_issue_page(issue)
    visit '/issues/' + issue.id.to_s
  end

  def visit_issue_bulk_edit_page(issues)
    visit url_for(:controller => 'issues', :action => 'bulk_edit', :ids => issues.collect(&:id))
  end

  def assert_forbidden
    assert_response :forbidden
    assert_template 'common/error'
  end

  def assert_requires_login
    assert_response :success
    assert_template 'account/login'
  end
  
end

class ActionController::IntegrationTest
  include IntegrationTestHelper
end

class ActiveSupport::TestCase
  begin
    require 'ruby_gc_test_patch'
    include RubyGcTestPatch
  rescue LoadError
  end

  def configure_overhead_plugin
    @custom_field = TimeEntryActivityCustomField.generate!
    Setting['plugin_redmine_overhead'] = {
      'custom_field' => @custom_field.id.to_s,
      'billable_value' => "true",
      'overhead_value' => "false"
    }
    
    @billable_activity = TimeEntryActivity.generate!.reload
    @billable_activity.custom_field_values = {
      @custom_field.id => 'true'
    }
    assert @billable_activity.save

    assert @billable_activity.billable?

    @non_billable_activity = TimeEntryActivity.generate!.reload
    @non_billable_activity.custom_field_values = {
      @custom_field.id => 'false'
    }
    assert @non_billable_activity.save

    assert !@non_billable_activity.billable?

  end
end
