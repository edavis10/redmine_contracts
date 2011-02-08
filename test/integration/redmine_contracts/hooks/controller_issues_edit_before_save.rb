require File.dirname(__FILE__) + '/../../../test_helper'

class RedmineContracts::Hooks::ControllerIssuesEditBeforeSaveTest < ActionController::IntegrationTest
  include Redmine::Hook::Helper

  context "#controller_issues_edit_before_save" do
    setup do
      @project = Project.generate!
      IssueStatus.generate!(:is_default => true)
      @issue = Issue.generate_for_project!(@project)
      @contract1 = Contract.generate!(:project => @project)
      @contract2 = Contract.generate!(:project => @project)
      
      @manager = User.generate!(:login => 'manager', :password => 'existing', :password_confirmation => 'existing', :admin => false)
      @role = Role.generate!(:permissions => [:view_issues, :add_issues, :edit_issues, :assign_deliverable_to_issue])
      User.add_to_project(@manager, @project, @role)
      @deliverable1 = FixedDeliverable.generate!(:contract => @contract1, :manager => @manager, :title => 'The Title for 1')
      @deliverable2 = FixedDeliverable.generate!(:contract => @contract2, :manager => @manager, :title => 'The Title for 2')

      login_as('manager', 'existing')
      @project.reload
    end

    context "for a new issue" do
      setup do
        visit_project(@project)
        click_link "New issue"
      end
      
      should "set the issue's deliverable" do
        fill_in "Subject", :with => 'Hook test'
        select @deliverable2.title, :from => "Deliverable"
        click_button "Create"

        assert_response :success

        assert_equal @deliverable2, Issue.last.deliverable

      end

      context "with no permission to Assign Deliverable" do
        should "not allow setting the Deliverable (force HTTP request)" do
          @role.permissions.delete(:assign_deliverable_to_issue)
          @role.save!

          assert_difference('Issue.count', 1) do
            post "/projects/#{@project.identifier}/issues", :issue => {:subject => 'Force', :deliverable_id => @deliverable1.id, :priority_id => IssuePriority.first.id}
          end

          assert_equal nil, Issue.last.deliverable
        end
      end
      
    end

    context "for an existing issue" do
      setup do
        visit_issue_page(@issue)
      end
      
      should "update the issue's deliverable" do
        select @deliverable2.title, :from => "Deliverable"
        click_button "Submit"

        assert_response :success

        @issue.reload
        assert_equal @deliverable2, @issue.deliverable

      end

      context "with no permission to Assign Deliverable" do
        should "not allow setting the Deliverable (force HTTP request)" do
          @role.permissions.delete(:assign_deliverable_to_issue)
          @role.save!

          assert_difference('Journal.count', 1) do
            put "/issues/#{@issue.id}", :issue => {:subject => 'Force', :deliverable_id => @deliverable1.id}
          end

          assert_equal nil, @issue.reload.deliverable
        end
      end

    end
  end
end
