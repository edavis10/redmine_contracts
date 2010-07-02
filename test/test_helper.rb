# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

# Ensure that we are using the temporary fixture path
Engines::Testing.set_fixture_path

require "webrat"

Webrat.configure do |config|
  config.mode = :rails
end

require 'holygrail'

module HolyGrail
  module Extensions
    # Need to rewrite the javascript for the engine too
    def rewrite_script_paths(body)
      body.
        gsub(%r%src=("|')/?plugin_assets/redmine_contracts/javascripts/(.*)("|')%) { %|src=#{$1}%s#{$1}"| % Rails.root.join("vendor/plugins/redmine_contracts/assets/javascripts/#{$2}") }.
        gsub(%r%src=("|')/?javascripts/(.*)("|')%) { %|src=#{$1}%s#{$1}"| % Rails.root.join("public/javascripts/#{$2}") }
    end
  end
end

class ActionController::TestCase
  include HolyGrail::Extensions
end
class ActionController::IntegrationTest
  include HolyGrail::Extensions
end

def User.add_to_project(user, project, role)
  Member.generate!(:principal => user, :project => project, :roles => [role])
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

  def assert_forbidden
    assert_response :forbidden
    assert_template 'common/403'
  end
  
end

class ActionController::IntegrationTest
  include IntegrationTestHelper
end
