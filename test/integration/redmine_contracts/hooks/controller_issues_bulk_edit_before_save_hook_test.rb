require File.dirname(__FILE__) + '/../../../test_helper'

class RedmineContracts::Hooks::ControllerIssuesBulkEditBeforeSaveHookTest < ActionController::IntegrationTest
  include Redmine::Hook::Helper

  context "#view_issues_bulk_edit_details_bottom" do
    setup do
      @project = Project.generate!
      @issue = Issue.generate_for_project!(@project)
      @issue2 = Issue.generate_for_project!(@project)
      @issue3 = Issue.generate_for_project!(@project)
      @issues = [@issue, @issue2, @issue3]
      @contract1 = Contract.generate!(:project => @project)
      @contract2 = Contract.generate!(:project => @project)
      
      @manager = User.generate!(:login => 'manager', :password => 'existing', :password_confirmation => 'existing')
      @role = Role.generate!(:permissions => [:view_issues, :edit_issues])
      User.add_to_project(@manager, @project, @role)
      @deliverable1 = FixedDeliverable.generate!(:contract => @contract1, :manager => @manager, :title => 'The Title 1')
      @deliverable2 = FixedDeliverable.generate!(:contract => @contract2, :manager => @manager, :title => 'The Title 2')
      @issue.deliverable = @deliverable1
      @issue.save

      login_as('manager', 'existing')
    end

    context "when saving multiple issues" do

      context "with permission to Assign Deliverable to Issue" do
        setup do
          @role.permissions << :assign_deliverable_to_issue
          @role.save!
          visit_issue_bulk_edit_page(@issues)
        end

        should "allow clearing all of the deliverables" do
          select "none", :from => "Deliverable"
          click_button "Submit"

          assert_response :success

          @issues.each do |issue|
            assert_equal nil, issue.reload.deliverable
          end
        end
        
        should "allow assigning a deliverable" do
          select @deliverable2.title, :from => "Deliverable"
          click_button "Submit"

          assert_response :success

          @issues.each do |issue|
            assert_equal @deliverable2, issue.reload.deliverable
          end
        end

      end

      context "with no permission to Assign Deliverable to Issue" do
        setup do
          @role.permissions.delete(:assign_deliverable_to_issue)
          @role.save!
          visit_issue_bulk_edit_page(@issues)
        end

        should "not allow clearing deliverables" do
          # Simulate form post since the field is hidden
          post "/issues/bulk_edit", :ids => @issues.collect(&:id), :deliverable_id => 'none'

          assert_response :redirect

          assert_equal @deliverable1, @issue.reload.deliverable
        end
        
        should "not allow assigning a deliverable" do
          # Simulate form post since the field is hidden
          post "/issues/bulk_edit", :ids => @issues.collect(&:id), :deliverable_id => @deliverable2.id

          assert_response :redirect

          @issues.each do |issue|
            assert_not_equal @deliverable2, issue.reload.deliverable
          end
        end

      end
      
    end
  end
end
