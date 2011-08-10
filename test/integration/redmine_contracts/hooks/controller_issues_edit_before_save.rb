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
      end
      
      should "set the issue's deliverable" do
        click_link "New issue"
        fill_in "Subject", :with => 'Hook test'
        select @deliverable2.title, :from => "Deliverable"
        click_button "Create"

        assert_response :success

        assert_equal @deliverable2, Issue.last.deliverable

      end

      should "not allow setting a locked Deliverable" do
        assert @deliverable2.lock!
        click_link "New issue"

        fill_in "Subject", :with => 'Hook test'
        select @deliverable2.title, :from => "Deliverable"
        assert_no_difference("Issue.count") do
          click_button "Create"

          assert_response :success
        end
        
        assert_equal nil, Issue.last.deliverable
        
      end

      should "not allow setting a closed Deliverable" do
        assert @deliverable2.close!
        click_link "New issue"

        fill_in "Subject", :with => 'Hook test'
        select @deliverable2.title, :from => "Deliverable"
        assert_no_difference("Issue.count") do
          click_button "Create"

          assert_response :success
        end
        
        assert_equal nil, Issue.last.deliverable
        
      end

      should "not allow setting a Deliverable on a locked Contract" do
        assert @contract2.lock!
        click_link "New issue"

        fill_in "Subject", :with => 'Hook test'
        select @deliverable2.title, :from => "Deliverable"
        assert_no_difference("Issue.count") do
          click_button "Create"

          assert_response :success
        end
        
        assert_equal nil, Issue.last.deliverable
        
      end

      should "not allow setting a Deliverable on a closed Contract" do
        assert @contract2.close!
        click_link "New issue"

        fill_in "Subject", :with => 'Hook test'
        select @deliverable2.title, :from => "Deliverable"
        assert_no_difference("Issue.count") do
          click_button "Create"

          assert_response :success
        end
        
        assert_equal nil, Issue.last.deliverable
        
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

      should "not allow updating to a locked deliverable" do
        assert @deliverable2.lock!
        select @deliverable2.title, :from => "Deliverable"
        click_button "Submit"

        assert_response :success

        @issue.reload
        assert_equal nil, @issue.deliverable

      end

      should "not allow updating to a closed deliverable" do
        assert @deliverable2.close!
        select @deliverable2.title, :from => "Deliverable"
        click_button "Submit"

        assert_response :success

        @issue.reload
        assert_equal nil, @issue.deliverable

      end

      should "not allow updating to a deliverable on a locked contract" do
        assert @contract2.lock!
        select @deliverable2.title, :from => "Deliverable"
        click_button "Submit"

        assert_response :success

        @issue.reload
        assert_equal nil, @issue.deliverable

      end

      should "not allow updating to a deliverable on a closed contract" do
        assert @contract2.close!
        select @deliverable2.title, :from => "Deliverable"
        click_button "Submit"

        assert_response :success

        @issue.reload
        assert_equal nil, @issue.deliverable

      end

      should "allow updating an issue, even if the deliverable is locked as long as the deliverable isn't changed" do
        select @deliverable2.title, :from => "Deliverable"
        click_button "Submit"

        assert_response :success

        @issue.reload
        assert_equal @deliverable2, @issue.deliverable

        # Now normal update after locking
        assert @deliverable2.lock!
        fill_in "Subject", :with => 'Change subject'
        click_button "Submit"

        assert_response :success
        @issue.reload
        assert_equal "Change subject", @issue.subject
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
