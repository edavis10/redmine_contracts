require File.dirname(__FILE__) + '/../test_helper'

class RetainerDeliverableTest < ActiveSupport::TestCase
  should "be a subclass of HourlyDeliverable" do
    assert_equal HourlyDeliverable, RetainerDeliverable.superclass
  end

  context "#months" do
    should "be an array of months the Deliverable is active in" do
      d = RetainerDeliverable.new(:start_date => Date.today.beginning_of_month,
                                  :end_date => 6.months.from_now)

      assert_equal 7, d.months.length # 6 months + current month
      d.months.each do |month|
        assert_kind_of Date, month
      end
    end

    should "return an empty array if start_date is missing" do
      d = RetainerDeliverable.new(:start_date => nil,
                                  :end_date => 6.months.from_now)
      assert_equal [], d.months
    end

    should "return an empty array if end_date is missing" do
      d = RetainerDeliverable.new(:start_date => Date.today.beginning_of_month,
                                  :end_date => nil)
      assert_equal [], d.months
    end

    should "return an empty array if the start_date and end_date are reversed" do
      d = RetainerDeliverable.new(:start_date => 6.months.from_now,
                                  :end_date => Date.today.beginning_of_month)
      assert_equal [], d.months
    end

  end

  context "#create_budgets_for_periods" do
    setup do
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-10',
                                                   :end_date => '2010-10-10')
      LaborBudget.generate!(:deliverable => @deliverable)
      OverheadBudget.generate!(:deliverable => @deliverable)
      OverheadBudget.generate!(:deliverable => @deliverable)
    end

    should "create a dated labor budget for each month" do
      assert_equal 1, @deliverable.labor_budgets.count

      @deliverable.reload.create_budgets_for_periods

      assert_equal 10, @deliverable.labor_budgets.count
      labor_budgets = @deliverable.labor_budgets
      labor_budgets.each do |budget|
        assert_equal 2010, budget.year
      end

      (1..10).each do |month_number|
        assert_equal 1, labor_budgets.select {|b| b.month == month_number}.length
      end
      
    end

    should "create a dated overhead budget for each month" do
      assert_equal 2, @deliverable.overhead_budgets.count

      @deliverable.reload.create_budgets_for_periods

      assert_equal 20, @deliverable.overhead_budgets.count
      overhead_budgets = @deliverable.overhead_budgets
      overhead_budgets.each do |budget|
        assert_equal 2010, budget.year
      end

      (1..10).each do |month_number|
        assert_equal 2, overhead_budgets.select {|b| b.month == month_number}.length
      end
      
    end
  end

  context "#labor_budget_spent" do
    setup do
      @project = Project.generate!
      @contract = Contract.generate!(:billable_rate => 100, :project => @project)
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31', :contract => @contract)
      @deliverable.labor_budgets << LaborBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.overhead_budgets << OverheadBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.save!

      @manager = User.generate!
      @role = Role.generate!
      User.add_to_project(@manager, @project, @role)

      configure_overhead_plugin

      @issue1 = Issue.generate_for_project!(@project)
      @time_entry1 = TimeEntry.generate!(:issue => @issue1,
                                         :project => @project,
                                         :activity => @billable_activity,
                                         :spent_on => Date.new(2010,1,2),
                                         :hours => 10,
                                         :user => @manager)
      @time_entry2 = TimeEntry.generate!(:issue => @issue1,
                                         :project => @project,
                                         :activity => @billable_activity,
                                         :spent_on => Date.new(2010,2,1),
                                         :hours => 20,
                                         :user => @manager)

      @rate = Rate.generate!(:project => @project,
                             :user => @manager,
                             :date_in_effect => Date.new(2010,1,1),
                             :amount => 100)

      @deliverable.issues << @issue1


    end

    context "with a empty period" do
      should "use all periods" do
        assert_equal (10+20) * 100, @deliverable.labor_budget_spent(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records periods" do
        assert_equal 0, @deliverable.labor_budget_spent(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.labor_budget_spent('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 20 * 100, @deliverable.labor_budget_spent(Date.new(2010,2,1))
      end
    end
  end

  context "#labor_budget_total" do
    setup do
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31')
      @deliverable.labor_budgets << LaborBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.save!
    end
    
    context "with a empty period" do
      should "use all periods" do
        assert_equal 300.0, @deliverable.labor_budget_total(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records" do
        assert_equal 0, @deliverable.labor_budget_total(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.labor_budget_total('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 100.0, @deliverable.labor_budget_total(Date.new(2010,2,1))
      end
    end
  end

  context "#labor_hours_spent_total" do
    setup do
      @project = Project.generate!
      @contract = Contract.generate!(:billable_rate => 100, :project => @project)
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31', :contract => @contract)

      @manager = User.generate!
      @role = Role.generate!
      User.add_to_project(@manager, @project, @role)

      configure_overhead_plugin

      @issue1 = Issue.generate_for_project!(@project)
      @time_entry1 = TimeEntry.generate!(:issue => @issue1,
                                         :project => @project,
                                         :activity => @billable_activity,
                                         :spent_on => Date.new(2010,1,2),
                                         :hours => 10,
                                         :user => @manager)
      @time_entry2 = TimeEntry.generate!(:issue => @issue1,
                                         :project => @project,
                                         :activity => @billable_activity,
                                         :spent_on => Date.new(2010,2,1),
                                         :hours => 20,
                                         :user => @manager)

      @rate = Rate.generate!(:project => @project,
                             :user => @manager,
                             :date_in_effect => Date.new(2010,1,1),
                             :amount => 100)

      @deliverable.issues << @issue1
      assert_equal 30, @deliverable.labor_hours_spent_total
    end
    
    context "with a empty period" do
      should "use all periods" do 
        assert_equal 30.0, @deliverable.labor_hours_spent_total(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records" do
        assert_equal 0, @deliverable.labor_hours_spent_total(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.labor_hours_spent_total('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 20.0, @deliverable.labor_hours_spent_total(Date.new(2010,2,1))
      end
    end
  end

  context "#overhead_hours_spent_total" do
    setup do
      @project = Project.generate!
      @contract = Contract.generate!(:billable_rate => 100, :project => @project)
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31', :contract => @contract)

      @manager = User.generate!
      @role = Role.generate!
      User.add_to_project(@manager, @project, @role)

      configure_overhead_plugin

      @issue1 = Issue.generate_for_project!(@project)
      @time_entry1 = TimeEntry.generate!(:issue => @issue1,
                                         :project => @project,
                                         :activity => @non_billable_activity,
                                         :spent_on => Date.new(2010,1,2),
                                         :hours => 10,
                                         :user => @manager)
      @time_entry2 = TimeEntry.generate!(:issue => @issue1,
                                         :project => @project,
                                         :activity => @non_billable_activity,
                                         :spent_on => Date.new(2010,2,1),
                                         :hours => 20,
                                         :user => @manager)

      @rate = Rate.generate!(:project => @project,
                             :user => @manager,
                             :date_in_effect => Date.new(2010,1,1),
                             :amount => 100)

      @deliverable.issues << @issue1
      assert_equal 30, @deliverable.overhead_hours_spent_total
    end
    
    context "with a empty period" do
      should "use all periods" do 
        assert_equal 30.0, @deliverable.overhead_hours_spent_total(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records" do
        assert_equal 0, @deliverable.overhead_hours_spent_total(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.overhead_hours_spent_total('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 20.0, @deliverable.overhead_hours_spent_total(Date.new(2010,2,1))
      end
    end
  end

  context "#overhead_spent" do
    setup do
      @project = Project.generate!
      @contract = Contract.generate!(:billable_rate => 100, :project => @project)
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31', :contract => @contract)
      @deliverable.overhead_budgets << OverheadBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.save!

      @manager = User.generate!
      @role = Role.generate!
      User.add_to_project(@manager, @project, @role)

      configure_overhead_plugin

      @issue1 = Issue.generate_for_project!(@project)
      @time_entry1 = TimeEntry.generate!(:issue => @issue1,
                                         :project => @project,
                                         :activity => @non_billable_activity,
                                         :spent_on => Date.new(2010,1,2),
                                         :hours => 10,
                                         :user => @manager)
      @time_entry2 = TimeEntry.generate!(:issue => @issue1,
                                         :project => @project,
                                         :activity => @non_billable_activity,
                                         :spent_on => Date.new(2010,2,1),
                                         :hours => 20,
                                         :user => @manager)

      @rate = Rate.generate!(:project => @project,
                             :user => @manager,
                             :date_in_effect => Date.new(2010,1,1),
                             :amount => 100)

      @deliverable.issues << @issue1


    end

    context "with a empty period" do
      should "use all periods" do
        assert_equal (10+20) * 100, @deliverable.overhead_spent(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records periods" do
        assert_equal 0, @deliverable.overhead_spent(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.overhead_spent('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 20 * 100, @deliverable.overhead_spent(Date.new(2010,2,1))
      end
    end
  end

  context "#overhead_budget_total" do
    setup do
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31')
      @deliverable.overhead_budgets << OverheadBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.save!
    end
    
    context "with a empty period" do
      should "use all periods" do
        assert_equal 300.0, @deliverable.overhead_budget_total(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records" do
        assert_equal 0, @deliverable.overhead_budget_total(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.overhead_budget_total('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 100.0, @deliverable.overhead_budget_total(Date.new(2010,2,1))
      end
    end
  end

  # (Labor used * contract rate) - (labor used * time rate) - (overhead used * time rate)
  context "#profit_left" do
    setup do
      @project = Project.generate!
      @contract = Contract.generate!(:billable_rate => 200, :project => @project)
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31', :contract => @contract)
      @deliverable.labor_budgets << LaborBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.overhead_budgets << OverheadBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.save!

      @manager = User.generate!
      @role = Role.generate!
      User.add_to_project(@manager, @project, @role)

      configure_overhead_plugin

      @issue1 = Issue.generate_for_project!(@project)
      @time_entry1 = TimeEntry.generate!(:issue => @issue1,
                                         :project => @project,
                                         :activity => @billable_activity,
                                         :spent_on => Date.new(2010,1,2),
                                         :hours => 10,
                                         :user => @manager)
      @time_entry2 = TimeEntry.generate!(:issue => @issue1,
                                         :project => @project,
                                         :activity => @non_billable_activity,
                                         :spent_on => Date.new(2010,2,1),
                                         :hours => 20,
                                         :user => @manager)

      @rate = Rate.generate!(:project => @project,
                             :user => @manager,
                             :date_in_effect => Date.new(2010,1,1),
                             :amount => 100)

      @deliverable.issues << @issue1


    end

    context "with a empty period" do
      should "use all periods" do
        assert_equal (10 * 200) - (10 * 100) - (20 * 100), @deliverable.profit_left(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records periods" do
        assert_equal 0, @deliverable.profit_left(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.profit_left('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal (0 * 200) - (0 * 100) - (20 * 100), @deliverable.profit_left(Date.new(2010,2,1))
      end
    end
  end

  
  context "#profit_budget" do
    setup do
      @contract = Contract.generate!(:billable_rate => 100)
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31', :contract => @contract)
      @deliverable.labor_budgets << LaborBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.overhead_budgets << OverheadBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.save!

      assert_equal 100 * 30, @deliverable.total
      assert_equal 2400, @deliverable.profit_budget # 3000 - 300 - 300
    end
    
    context "with a empty period" do
      should "use all periods" do
        assert_equal 2400, @deliverable.profit_budget(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records" do
        assert_equal 0, @deliverable.profit_budget(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.profit_budget('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 1000 - 200, @deliverable.profit_budget(Date.new(2010,2,1))
      end
    end

  end
  
  context "#total_spent" do
    setup do
      @project = Project.generate!
      @contract = Contract.generate!(:billable_rate => 200, :project => @project)
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31', :contract => @contract)
      @deliverable.labor_budgets << LaborBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.overhead_budgets << OverheadBudget.spawn(:budget => 100, :hours => 10)
      # Only paid fixed budgets counted
      @deliverable.fixed_budgets << FixedBudget.generate!(:budget => '$100', :markup => '50%') # $50 markup
      @deliverable.fixed_budgets << FixedBudget.generate!(:budget => '$100', :markup => '50%', :paid => true) # $50 markup

      @deliverable.save!

      @manager = User.generate!
      @role = Role.generate!
      User.add_to_project(@manager, @project, @role)

      configure_overhead_plugin

      @issue1 = Issue.generate_for_project!(@project)
      @time_entry1 = TimeEntry.generate!(:issue => @issue1,
                                         :project => @project,
                                         :activity => @billable_activity,
                                         :spent_on => Date.new(2010,1,2),
                                         :hours => 10,
                                         :user => @manager)
      @time_entry2 = TimeEntry.generate!(:issue => @issue1,
                                         :project => @project,
                                         :activity => @billable_activity,
                                         :spent_on => Date.new(2010,2,1),
                                         :hours => 20,
                                         :user => @manager)

      @rate = Rate.generate!(:project => @project,
                             :user => @manager,
                             :date_in_effect => Date.new(2010,1,1),
                             :amount => 100)

      @deliverable.issues << @issue1
    end

    context "with a empty period" do
      should "use all periods" do
        # (Labor used * contract rate) + fixed
        assert_equal ((10+20) * 200) + (150 * 3), @deliverable.total_spent(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records periods" do
        assert_equal 0, @deliverable.total_spent(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.total_spent('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal (20 * 200) + 150, @deliverable.total_spent(Date.new(2010,2,1))
      end
    end
  end

  context "#total" do
    setup do
      @contract = Contract.generate!(:billable_rate => 100)
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31', :contract => @contract)
      @deliverable.labor_budgets << LaborBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.overhead_budgets << OverheadBudget.spawn(:budget => 100, :hours => 10)
      @deliverable.save!

      assert_equal 100 * 30, @deliverable.total
    end
    
    context "with a empty period" do
      should "use all periods" do
        assert_equal 3000, @deliverable.total(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records" do
        assert_equal 0, @deliverable.total(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.total('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 1000, @deliverable.total(Date.new(2010,2,1))
      end
    end

  end

  context "#fixed_budget_total" do
    setup do
      @contract = Contract.generate!(:billable_rate => 100)
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31', :contract => @contract)
      @deliverable.fixed_budgets << FixedBudget.spawn(:budget => 1000)
      @deliverable.fixed_budgets << FixedBudget.spawn(:budget => 2000)
      @deliverable.save!

      assert_equal 3000 * 3, @deliverable.fixed_budget_total
    end
    
    context "with a empty period" do
      should "use all periods" do
        assert_equal 9000, @deliverable.fixed_budget_total(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records" do
        assert_equal 0, @deliverable.fixed_budget_total(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.fixed_budget_total('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 3000, @deliverable.fixed_budget_total(Date.new(2010,2,1))
      end
    end

  end

  context "#fixed_budget_total_spent" do
    setup do
      @contract = Contract.generate!(:billable_rate => 100)
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31', :contract => @contract)
      @deliverable.fixed_budgets << FixedBudget.spawn(:budget => 1000, :paid => true)
      @deliverable.fixed_budgets << FixedBudget.spawn(:budget => 2000)
      @deliverable.save!

      assert_equal 1000 * 3, @deliverable.fixed_budget_total_spent
    end
    
    context "with a empty period" do
      should "use all periods" do
        assert_equal 3000, @deliverable.fixed_budget_total_spent(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records" do
        assert_equal 0, @deliverable.fixed_budget_total_spent(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.fixed_budget_total_spent('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 1000, @deliverable.fixed_budget_total_spent(Date.new(2010,2,1))
      end
    end

  end

  context "#fixed_markup_budget_total" do
    setup do
      @contract = Contract.generate!(:billable_rate => 100)
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31', :contract => @contract)
      @deliverable.fixed_budgets << FixedBudget.spawn(:budget => 1000, :markup => '50%')
      @deliverable.fixed_budgets << FixedBudget.spawn(:budget => 2000, :markup => '$1000')
      @deliverable.save!

      assert_equal (500 + 1000) * 3, @deliverable.fixed_markup_budget_total
    end
    
    context "with a empty period" do
      should "use all periods" do
        assert_equal 4500, @deliverable.fixed_markup_budget_total(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records" do
        assert_equal 0, @deliverable.fixed_markup_budget_total(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.fixed_markup_budget_total('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 1500, @deliverable.fixed_markup_budget_total(Date.new(2010,2,1))
      end
    end

  end

  context "#fixed_markup_budget_total_spent" do
    setup do
      @contract = Contract.generate!(:billable_rate => 100)
      @deliverable = RetainerDeliverable.generate!(:start_date => '2010-01-01', :end_date => '2010-03-31', :contract => @contract)
      @deliverable.fixed_budgets << FixedBudget.spawn(:budget => 1000, :markup => '50%', :paid => true)
      @deliverable.fixed_budgets << FixedBudget.spawn(:budget => 2000, :markup => '$1000')
      @deliverable.save!

      assert_equal (500) * 3, @deliverable.fixed_markup_budget_total_spent
    end
    
    context "with a empty period" do
      should "use all periods" do
        assert_equal 1500, @deliverable.fixed_markup_budget_total_spent(nil)
      end
    end

    context "with a period out of the retainer range" do
      should "filter the records" do
        assert_equal 0, @deliverable.fixed_markup_budget_total_spent(Date.new(2011,1,1))
      end
    end

    context "with an invalid period" do
      should "return 0" do
        assert_equal 0, @deliverable.fixed_markup_budget_total_spent('1')
      end
    end

    context "with a period in the retainer range" do
      should "filter the records" do
        assert_equal 500, @deliverable.fixed_markup_budget_total_spent(Date.new(2010,2,1))
      end
    end

  end
end
