require 'test_helper'

class DeliverableFinancesShowTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    configure_overhead_plugin
    @project = Project.generate!(:identifier => 'main').reload
    @contract = Contract.generate!(:project => @project, :billable_rate => 10)
    @manager = User.generate!.reload
    @deliverable1 = RetainerDeliverable.spawn(:contract => @contract, :manager => @manager, :title => "Retainer Title", :start_date => '2010-01-01', :end_date => '2010-03-31')
    @deliverable1.labor_budgets << LaborBudget.spawn(:budget => 100, :hours => 10, :time_entry_activity => @billable_activity)
    @deliverable1.overhead_budgets << OverheadBudget.spawn(:budget => 200, :hours => 10)

    @deliverable1.save!
    @user = User.generate_user_with_permission_to_manage_budget(:project => @project)
    @category_on_billable = IssueCategory.generate!(:project => @project).reload
    @category_on_non_billable = IssueCategory.generate!(:project => @project).reload
    # 2 hours of $100 billable work
    create_issue_with_time_for_deliverable(@deliverable1, {
                                             :activity => @billable_activity,
                                             :user => @manager,
                                             :hours => 2,
                                             :amount => 100,
                                             :issue_category => @category_on_billable
                                           })
    # 1 hour of $100 billable work with no category
    create_issue_with_time_for_deliverable(@deliverable1, {
                                             :activity => @billable_activity,
                                             :user => @manager,
                                             :hours => 1,
                                             :amount => 100,
                                             :issue_category => nil
                                           })
    # 5 hours of $100 nonbillable work
    create_issue_with_time_for_deliverable(@deliverable1, {
                                             :activity => @non_billable_activity,
                                             :user => @manager,
                                             :hours => 5,
                                             :amount => 100,
                                             :issue_category => @category_on_non_billable
                                           })

    @user.reload
    login_as(@user.login, 'contracts')
  end

  context "for an anonymous request" do
    should "require login" do
      logout

      visit "/projects/#{@project.id}/contracts/#{@contract.id}/deliverables/#{@deliverable1.id}/finances"

      assert_response :success
      assert_template 'account/login'
    end

  end

  context "for an unauthorized request" do
    should "be forbidden" do
      logout

      @user = User.generate!(:password => 'test', :password_confirmation => 'test')
      login_as(@user.login, 'test')

      visit "/projects/#{@project.id}/contracts/#{@contract.id}/deliverables/#{@deliverable1.id}/finances"

      assert_response :forbidden
    end

  end


  context "for an authorized request" do
    setup do
      visit "/projects/#{@project.id}/contracts/#{@contract.id}/deliverables/#{@deliverable1.id}/finances"

      assert_response :success
    end
    
    should "render the finance report title section for the deliverable" do
      assert_select "h2", :text => /#{@deliverable1.title}/

      assert_select "div#finance-summary" do
        assert_select "span.spent", :text => /\$300/ # ($100 * 2) + ($100 * 1)
        assert_select "span.total", :text => /\$300/ # $100 * 3
        assert_select "span.hours", :text => /3/
      end
    end

    should "render the labor activities table for the deliverable" do
      assert_select "table#deliverable-labor-activities" do
        assert_select "tr.labor" do
          assert_select "td", :text => /#{@billable_activity.name}/
          assert_select "td.spent-amount", :text => /\$300/
          assert_select "td.total-amount", :text => /\$300/
          assert_select "td.spent-hours", :text => /3/
          assert_select "td.total-deliverable-hours", :text => /30/ # 3 month retainer * 10
        end

        assert_select "tr.summary-row.labor" do
          assert_select "td", :text => /Totals/
          assert_select "td.spent-amount", :text => /\$300/
          assert_select "td.total-amount", :text => /\$300/
          assert_select "td.spent-hours", :text => /3/
          assert_select "td.total-deliverable-hours", :text => /30/
        end

      end
    end

    should "render the overhead activities table for the deliverable" do
      assert_select "table#deliverable-overhead-activities" do
        assert_select "tr.overhead" do
          assert_select "td", :text => /#{@non_billable_activity.name}/
          assert_select "td.spent-amount", :text => /\$500/
          assert_select "td.total-amount", :text => /\$600/
          assert_select "td.spent-hours", :text => /5/
          assert_select "td.total-deliverable-hours", :text => /30/ # 3 month retainer * 10
        end

        assert_select "tr.summary-row.overhead" do
          assert_select "td", :text => /Totals/
          assert_select "td.spent-amount", :text => /\$500/
          assert_select "td.total-amount", :text => /\$600/
          assert_select "td.spent-hours", :text => /5/
          assert_select "td.total-deliverable-hours", :text => /30/
        end

      end
    end

    should "render the labor finances for each user for the deliverable" do
      assert_select "table#deliverable-labor-users" do
        assert_select "tr.labor" do
          assert_select "td", :text => /#{@manager.name}/
          assert_select "td.amount-cost", :text => /\$300/
          assert_select "td.time-cost", :text => /3/
        end

        assert_select "tr.summary-row" do
          assert_select "td", :text => /Totals/
          assert_select "td.amount-cost", :text => /\$300/
          assert_select "td.time-cost", :text => /3/
        end

      end
    end

    should "render the overhead finances for each user for the deliverable" do
      assert_select "table#deliverable-overhead-users" do
        assert_select "tr.overhead" do
          assert_select "td", :text => /#{@manager.name}/
          assert_select "td.amount-cost", :text => /\$500/
          assert_select "td.time-cost", :text => /5/
        end

        assert_select "tr.summary-row.overhead" do
          assert_select "td", :text => /Totals/
          assert_select "td.amount-cost", :text => /\$500/
          assert_select "td.time-cost", :text => /5/
        end

      end
    end

    should "render the labor finances for each Issue Category for the deliverable" do
      assert_select "table#deliverable-labor-issue-categories" do
        assert_select "tr.labor" do
          assert_select "td", :text => /#{@category_on_billable.name}/
          assert_select "td.amount-cost", :text => /\$200/
          assert_select "td.time-cost", :text => /2/
        end

        assert_select "tr.labor" do
          assert_select "td", :text => /none/
          assert_select "td.amount-cost", :text => /\$100/
          assert_select "td.time-cost", :text => /1/
        end

        assert_select "tr.summary-row" do
          assert_select "td", :text => /Totals/
          assert_select "td.amount-cost", :text => /\$300/
          assert_select "td.time-cost", :text => /3/
        end

      end
    end

    should "render the overhead finances for each Issue Category for the deliverable" do
      assert_select "table#deliverable-overhead-issue-categories" do
        assert_select "tr.overhead" do
          assert_select "td", :text => /#{@category_on_non_billable.name}/
          assert_select "td.amount-cost", :text => /\$500/
          assert_select "td.time-cost", :text => /5/
        end

        assert_select "tr.summary-row.overhead" do
          assert_select "td", :text => /Totals/
          assert_select "td.amount-cost", :text => /\$500/
          assert_select "td.time-cost", :text => /5/
        end

      end
    end
  end
end
