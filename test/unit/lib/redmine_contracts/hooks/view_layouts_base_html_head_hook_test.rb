require File.dirname(__FILE__) + '/../../../../test_helper'

class RedmineContracts::Hooks::ViewLayoutsBaseHtmlHeadTest < ActionController::TestCase
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
    call_hook :view_layouts_base_html_head, args
  end

  context "#view_layouts_base_html_head" do
    context "for any non-contracts plugin controller" do
      should "return an empty string" do
        @response.body = hook
        assert @response.body.blank?
      end
    end

    context "for Contracts Controller" do
      setup do
        @controller = ContractsController.new
        @controller.response = ActionController::TestResponse.new
      end

      should "load the redmine_contracts.css stylesheet" do
        @response.body = hook
        assert_select "link[href*=?]", "redmine_contracts.css"
      end

      should "load jquery" do
        @response.body = hook
        assert_select "script[src*=?]", "jquery-1.4.2.min.js"
      end

      should "load the contracts.js JavaScript" do
        @response.body = hook
        assert_select "script[src*=?]", "contracts.js"
      end
    end

    context "for Deliverables Controller" do
      setup do
        @controller = DeliverablesController.new
        @controller.response = ActionController::TestResponse.new
      end

      should "load the redmine_contracts.css stylesheet" do
        @response.body = hook
        assert_select "link[href*=?]", "redmine_contracts.css"
      end

      should "load jquery" do
        @response.body = hook
        assert_select "script[src*=?]", "jquery-1.4.2.min.js"
      end

      should "load the contracts.js JavaScript" do
        @response.body = hook
        assert_select "script[src*=?]", "contracts.js"
      end
    end
  end
end
