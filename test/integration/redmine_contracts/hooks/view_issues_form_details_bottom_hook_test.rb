require File.dirname(__FILE__) + '/../../../test_helper'

class RedmineContracts::Hooks::ViewIssuesFormDetailsBottomTest < ActionController::IntegrationTest
  include Redmine::Hook::Helper

  context "#view_issues_form_details_bottom" do
    setup do
      @project = Project.generate!
      @issue = Issue.generate_for_project!(@project)
      @contract1 = Contract.generate!(:project => @project)
      @contract2 = Contract.generate!(:project => @project)
      
      @manager = User.generate!(:login => 'manager', :password => 'existing', :password_confirmation => 'existing')
      @role = Role.generate!(:permissions => [:view_issues, :edit_issues])
      User.add_to_project(@manager, @project, @role)
      @deliverable1 = FixedDeliverable.generate!(:contract => @contract1, :manager => @manager, :title => 'The Title')
      @deliverable2 = FixedDeliverable.generate!(:contract => @contract2, :manager => @manager, :title => 'The Title')
      @issue.deliverable = @deliverable1

      login_as('manager', 'existing')
    end

    context "with Contracts Enabled" do
      setup do
        visit_issue_page(@issue)
      end
      
      should "render the a select field for the deliverables with all of the deliverables grouped by contract" do
        assert_select "select#issue_deliverable_id" do
          assert_select "optgroup[label=?]", @contract1.name do
            assert_select "option", :text => /#{@deliverable1.title}/
          end

          assert_select "optgroup[label=?]", @contract2.name do
            assert_select "option", :text => /#{@deliverable2.title}/
          end
        end
      end
    end

    context "with Contracts Disabled" do
      setup do
        @project.enabled_modules.collect {|m| m.destroy if m.name == 'contracts' }
        visit_issue_page(@issue)
      end

      should "not render the deliverable select field" do
        assert_select 'select#issue_deliverable_id', :count => 0
      end
    end
  end
end
