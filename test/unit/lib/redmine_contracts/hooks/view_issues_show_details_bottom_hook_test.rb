require File.dirname(__FILE__) + '/../../../../test_helper'

class RedmineContracts::Hooks::ViewIssuesShowDetailsBottomTest < ActionController::TestCase
  include Redmine::Hook::Helper

  # Bloody bloody hack to work around Rails coupling of _VC.
  def template
    t = ActionView::Base.new(ActionController::Base.view_paths, {}, @controller)
    def t.template_format
      "html"
    end

    # Rendered views aren't getting access to the controller's I18n module
    t.send(:extend, Redmine::I18n)
    t
  end
  
  def controller
    @controller ||= ApplicationController.new
    @controller.class.send(:include, ::Redmine::I18n)
    @controller.response ||= ActionController::TestResponse.new
    def @controller.api_request?
      false
    end
    # Hack to support render_on
    @controller.instance_variable_set('@template', template)
    @controller.response = response
    @controller
  end

  def request
    @request ||= ActionController::TestRequest.new
  end

  # Hack to support render_on
  def response
    @response.template ||= template
    @response
  end
  
  def hook(args={})
    call_hook :view_issues_show_details_bottom, args
  end

  context "#view_issues_show_details_bottom" do
    setup do
      @project = Project.generate!
      @issue = Issue.generate_for_project!(@project)
      @contract = Contract.generate!(:project => @project)

      @manager = User.generate!
      @role = Role.generate!
      User.add_to_project(@manager, @project, @role)
      @deliverable = FixedDeliverable.generate!(:contract => @contract, :manager => @manager, :title => 'The Title')
      @issue.deliverable = @deliverable
    end

    context "with Contracts Enabled" do
      should "render the deliverable's name" do
        @response.body = hook(:project => @project, :issue => @issue, :controller => controller)

        assert_select "tr" do
          assert_select "td", :text => /#{@deliverable.title}/
        end          
      end
    end

    context "with Contracts Disabled" do
      setup do
        @project.enabled_modules.destroy_all
      end

      should "not render the deliverable's name" do
        @response.body = hook(:project => @project, :issue => @issue, :controller => controller)

        assert_no_match /#{@deliverable.title}/, @response.body
      end
    end
  end
end
