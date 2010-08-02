require File.dirname(__FILE__) + '/../../../../test_helper'

class RedmineContracts::Hooks::ViewIssuesFormDetailsBottomTest < ActionController::TestCase
  include Redmine::Hook::Helper

  def controller
    @controller ||= ApplicationController.new
    @controller.response ||= ActionController::TestResponse.new
    @controller
  end

  def request
    @request ||= ActionController::TestRequest.new
  end
  
  def hook(args={})
    call_hook :view_issues_form_details_bottom, args
  end

  context "#view_issues_form_details_bottom" do
    should "return an empty string" do
      @response.body = hook
      assert @response.body.blank?
    end
  end
end
