require File.dirname(__FILE__) + '/../../../test_helper'

class RedmineContracts::Hooks::ViewIssuesFormDetailsBottomTest < ActionController::IntegrationTest
  include Redmine::Hook::Helper

  context "#view_issues_form_details_bottom" do
    setup do
      @project = Project.generate!
      @issue = Issue.generate_for_project!(@project)
      @contract1 = Contract.generate!(:project => @project)
      @contract2 = Contract.generate!(:project => @project)
      @locked_contract = Contract.generate!(:project => @project, :status => 'locked')
      @closed_contract = Contract.generate!(:project => @project, :status => 'closed')
      
      @manager = User.generate!(:login => 'manager', :password => 'existing', :password_confirmation => 'existing')
      @role = Role.generate!(:permissions => [:view_issues, :edit_issues])
      User.add_to_project(@manager, @project, @role)
      @deliverable1 = FixedDeliverable.generate!(:contract => @contract1, :manager => @manager, :title => 'Deliverable1')
      @deliverable2 = FixedDeliverable.generate!(:contract => @contract2, :manager => @manager, :title => 'Deliverable2')
      @locked_deliverable = FixedDeliverable.generate!(:contract => @contract1, :manager => @manager, :title => 'Locked Deliverable', :status => 'locked')
      @closed_deliverable = FixedDeliverable.generate!(:contract => @contract1, :manager => @manager, :title => 'Closed Deliverable', :status => 'closed')
      @deliverable1_on_locked_contract = FixedDeliverable.generate!(:contract => @locked_contract, :manager => @manager, :title => 'Deliverable 1 on locked contract')
      @deliverable2_on_locked_contract = FixedDeliverable.generate!(:contract => @locked_contract, :manager => @manager, :title => 'Deliverable 2 on locked contract')
      @deliverable_on_closed_contract = FixedDeliverable.generate!(:contract => @closed_contract, :manager => @manager, :title => 'Deliverable on closed contract')
      @issue.deliverable = @deliverable1
      assert @issue.save

      login_as('manager', 'existing')
    end

    context "with Contracts Enabled" do
      context "with permission to Assign Deliverable" do
        setup do
          @role.permissions << :assign_deliverable_to_issue
          @role.save!
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

        should "disable all locked deliverables" do
          assert_select "select#issue_deliverable_id" do
            assert_select "option[disabled=disabled]", :text => /#{@locked_deliverable.title}/
          end
        end
        
        should "disable all deliverables on locked contracts" do
          assert_select "select#issue_deliverable_id" do
            assert_select "optgroup[label=?]", @locked_contract.name do
              assert_select "option[disabled=disabled]", :text => /#{@deliverable1_on_locked_contract.title}/
              assert_select "option[disabled=disabled]", :text => /#{@deliverable2_on_locked_contract.title}/
            end
          end
        end
        
        should "not show closed deliverables" do
          assert_select "select#issue_deliverable_id" do
            assert_select "option", :text => /#{@closed_deliverable.title}/, :count => 0
          end
        end

        should "not show deliverables on closed contracts" do
          assert_select "select#issue_deliverable_id" do
            assert_select "optgroup[label=?]", @closed_contract.name, :count => 0
            assert_select "option", :text => /#{@deliverable_on_closed_contract.title}/, :count => 0
          end
        end

        should "show the assigned deliverable as an option, even if it's locked" do
          @deliverable1.lock!
          visit_issue_page(@issue)

          assert_select "select#issue_deliverable_id" do
            assert_select "option[disabled=disabled]", :text => /#{@deliverable1.title}/, :count => 0 # Not disabled
            assert_select "option", :text => /#{@deliverable1.title}/, :count => 1 # Present
          end

        end

        should "show the assigned deliverable as an option, even if it's closed" do
          @deliverable1.close!
          visit_issue_page(@issue)

          assert_select "select#issue_deliverable_id" do
            assert_select "option[disabled=disabled]", :text => /#{@deliverable1.title}/, :count => 0 # Not disabled
            assert_select "option", :text => /#{@deliverable1.title}/, :count => 1 # Present
          end

        end

        should "show the assigned deliverable as an option, even if it's contract is locked" do
          @contract1.lock!
          visit_issue_page(@issue)

          assert_select "select#issue_deliverable_id" do
            assert_select "option[disabled=disabled]", :text => /#{@deliverable1.title}/, :count => 0 # Not disabled
            assert_select "option", :text => /#{@deliverable1.title}/, :count => 1 # Present
          end

        end

        should "show the assigned deliverable as an option, even if it's contract is closed" do
          @contract1.close!
          visit_issue_page(@issue)

          assert_select "select#issue_deliverable_id" do
            assert_select "option[disabled=disabled]", :text => /#{@deliverable1.title}/, :count => 0 # Not disabled
            assert_select "option", :text => /#{@deliverable1.title}/, :count => 1 # Present
          end

        end
      end
      
      context "with no permission to Assign Deliverable" do
        setup do
          @role.permissions.delete(:assign_deliverable_to_issue)
          @role.save!
          visit_issue_page(@issue)
        end

        should "not render the deliverable select field" do
          assert_select 'select#issue_deliverable_id', :count => 0
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
