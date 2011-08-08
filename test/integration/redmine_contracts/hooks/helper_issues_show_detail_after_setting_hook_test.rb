require File.dirname(__FILE__) + '/../../../test_helper'

class RedmineContracts::Hooks::HelperIssuesShowDetailAfterSettingHookTest < ActionController::IntegrationTest
  include Redmine::Hook::Helper

  context "#helper_issues_show_detail_after_setting" do
    setup do
      @project = Project.generate!
      @issue = Issue.generate_for_project!(@project)

      @contract1 = Contract.generate!(:project => @project)
      @contract2 = Contract.generate!(:project => @project)
      
      @manager = User.generate!(:login => 'manager', :password => 'existing', :password_confirmation => 'existing')
      @role = Role.generate!(:permissions => [:view_issues, :edit_issues])
      User.add_to_project(@manager, @project, @role)
      @deliverable1 = FixedDeliverable.generate!(:contract => @contract1, :manager => @manager, :title => 'The Title 1')
      @deliverable2 = FixedDeliverable.generate!(:contract => @contract2, :manager => @manager, :title => 'The Title 2')
      # Set first
      @issue.init_journal(@manager)
      @issue.deliverable = @deliverable1
      @issue.save! && @issue.reload
      # Change
      @issue.init_journal(@manager)
      @issue.deliverable = @deliverable2
      @issue.save! && @issue.reload
      # Unset
      @issue.init_journal(@manager)
      @issue.deliverable = nil
      @issue.save! && @issue.reload
      
      login_as('manager', 'existing')

      visit_issue_page(@issue)
      assert_response :success
    end

    should "show when a deliverable is set" do
      assert_select ".details" do
        assert_select "li", :text => /Deliverable set to #{@deliverable1.title}/
      end
    end

    should "show when a deliverable is changed" do
      assert_select ".details" do
        assert_select "li", :text => /Deliverable changed from #{@deliverable1.title} to #{@deliverable2.title}/
      end

    end

    should "show when a deliverable is removed" do
      assert_select ".details" do
        assert_select "li", :text => /Deliverable deleted .*#{@deliverable2.title}/
      end

    end
  end
end
