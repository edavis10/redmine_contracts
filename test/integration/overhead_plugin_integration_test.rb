require 'test_helper'

class OverheadPluginIntegrationTest < ActionController::IntegrationTest
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project, :name => 'A Contract', :payment_terms => 'net_15')
    @manager = User.generate!
    @role = Role.generate!
    User.add_to_project(@manager, @project, @role)
    @fixed_deliverable = FixedDeliverable.generate!(:contract => @contract, :manager => @manager, :title => 'The Title')
    @hourly_deliverable = HourlyDeliverable.generate!(:contract => @contract, :manager => @manager, :title => 'An Hourly')

    configure_overhead_plugin
  end
  
  context "Patches to Deliverable" do
    context "#overhead_spent" do
      should "return the total cost for all of the time on the issues for non-billable activities"
    end
  end
  
  context "Patches to HourlyDeliverable" do
    context "#labor_budget_spent" do
      should "return 0 if there are no issues assigned" do
        assert_equal 0, @hourly_deliverable.issues.count
        
        assert_equal 0, @hourly_deliverable.labor_budget_spent
      end
      
      should "return the total cost for all of the time on the issues for billable activities" do

        @issue1 = Issue.generate_for_project!(@project)
        @time_entry1 = TimeEntry.generate!(:issue => @issue1,
                                           :project => @project,
                                           :activity => @billable_activity,
                                           :spent_on => Date.today,
                                           :hours => 10,
                                           :user => @manager)
        @time_entry2 = TimeEntry.generate!(:issue => @issue1,
                                           :project => @project,
                                           :activity => @non_billable_activity,
                                           :spent_on => Date.today,
                                           :hours => 10,
                                           :user => @manager)

        @rate = Rate.generate!(:project => @project,
                               :user => @manager,
                               :date_in_effect => Date.yesterday,
                               :amount => 100)

        @hourly_deliverable.issues << @issue1

        assert_equal 1, @hourly_deliverable.issues.count

        assert_equal 10 * 100, @hourly_deliverable.labor_budget_spent
        
      end
    end
  end

  context "Patches to FixedDeliverable" do
    context "#labor_budget_spent" do
      should "return 0 if there are no issues assigned" do
        assert_equal 0, @fixed_deliverable.issues.count

        assert_equal 0, @fixed_deliverable.labor_budget_spent
      end

      should "return the total cost for all of the time on the issues for billable activities" do
        @issue1 = Issue.generate_for_project!(@project)
        @time_entry1 = TimeEntry.generate!(:issue => @issue1,
                                           :project => @project,
                                           :activity => @billable_activity,
                                           :spent_on => Date.today,
                                           :hours => 10,
                                           :user => @manager)
        @time_entry2 = TimeEntry.generate!(:issue => @issue1,
                                           :project => @project,
                                           :activity => @non_billable_activity,
                                           :spent_on => Date.today,
                                           :hours => 10,
                                           :user => @manager)

        @rate = Rate.generate!(:project => @project,
                               :user => @manager,
                               :date_in_effect => Date.yesterday,
                               :amount => 100)

        @fixed_deliverable.issues << @issue1

        assert_equal 1, @fixed_deliverable.issues.count

        assert_equal 10 * 100, @fixed_deliverable.labor_budget_spent
        
      end
    end
  end

end
