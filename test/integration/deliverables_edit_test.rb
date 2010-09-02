require 'test_helper'

class DeliverablesEditTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project, :name => 'A Contract')
    @manager = User.generate!
    @role = Role.generate!
    User.add_to_project(@manager, @project, @role)
    @fixed_deliverable = FixedDeliverable.generate!(:contract => @contract, :manager => @manager, :title => 'The Title')
    @hourly_deliverable = HourlyDeliverable.generate!(:contract => @contract, :manager => @manager, :title => 'An Hourly')
    
  end

  should "allow any user to edit the Fixed deliverable" do
    visit_contract_page(@contract)
    click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
    assert_response :success
    assert_template 'deliverables/edit'

    assert_select "form#edit_fixed_deliverable_#{@fixed_deliverable.id}" do
      assert_select "input#fixed_deliverable_title[value=?]", /#{@fixed_deliverable.title}/
    end

    assert_select "select#fixed_deliverable_type", :count => 0 # Not editable
    assert js("jQuery('#fixed_deliverable_total_input').is(':visible')"), "Total is hidden when it should be visible"


    fill_in "Title", :with => 'An updated title'
    check "Feature Sign Off"
    check "Warranty Sign Off"
    click_button "Save"

    assert_response :success
    assert_template 'contracts/show'

    assert_equal "An updated title", @fixed_deliverable.reload.title
    assert_equal "FixedDeliverable", @fixed_deliverable.reload.type
    assert @fixed_deliverable.reload.warranty_sign_off?
    assert @fixed_deliverable.reload.feature_sign_off?

  end

  should "allow any user to edit the Hourly deliverable" do
    visit_contract_page(@contract)
    click_link_within "#deliverable_details_#{@hourly_deliverable.id}", 'Edit'
    assert_response :success
    assert_template 'deliverables/edit'

    assert_select "form#edit_hourly_deliverable_#{@hourly_deliverable.id}" do
      assert_select "input#hourly_deliverable_title[value=?]", /#{@hourly_deliverable.title}/
    end

    assert_select "select#hourly_deliverable_type", :count => 0 # Not editable
    assert js("jQuery('#hourly_deliverable_total_input').is(':hidden')"), "Total is visible when it should be hidden"
    
    fill_in "Title", :with => 'An updated title'
    check "Feature Sign Off"
    check "Warranty Sign Off"

    within("#deliverable-labor") do
      fill_in "hrs", :with => '20'
      fill_in "$", :with => '$2,000'
    end

    within("#deliverable-overhead") do
      fill_in "hrs", :with => '10'
      fill_in "$", :with => '$1,000'
    end

    click_button "Save"

    assert_response :success
    assert_template 'contracts/show'

    assert_equal "An updated title", @hourly_deliverable.reload.title
    assert_equal "HourlyDeliverable", @hourly_deliverable.reload.type
    assert @hourly_deliverable.reload.warranty_sign_off?
    assert @hourly_deliverable.reload.feature_sign_off?

    assert_equal 1, @hourly_deliverable.labor_budgets.count
    @labor_budget = @hourly_deliverable.labor_budgets.first
    assert_equal 20, @labor_budget.hours
    assert_equal 2000.0, @labor_budget.budget

    assert_equal 1, @hourly_deliverable.overhead_budgets.count
    @overhead_budget = @hourly_deliverable.overhead_budgets.first
    assert_equal 10, @overhead_budget.hours
    assert_equal 1000.0, @overhead_budget.budget
  end

  should "show allow editing the Deliverable Finances section for each Retainer period" do
    @retainer_deliverable = RetainerDeliverable.spawn(:contract => @contract, :manager => @manager, :title => "Retainer")
    @retainer_deliverable.labor_budgets << @labor_budget = LaborBudget.spawn(:deliverable => @retainer_deliverable, :budget => 1000, :hours => 10)
    @retainer_deliverable.overhead_budgets << @overhead_budget = OverheadBudget.spawn(:deliverable => @retainer_deliverable, :budget => 1000, :hours => 10)
    @retainer_deliverable.start_date = '2010-01-01'
    @retainer_deliverable.end_date = '2010-12-31'
    @retainer_deliverable.save!
    assert_equal 12, @retainer_deliverable.months.length

    visit_contract_page(@contract)
    click_link_within "#deliverable_details_#{@retainer_deliverable.id}", 'Edit'
    assert_response :success
    assert_template 'deliverables/edit'

    assert_select 'fieldset.deliverable-finances', :count => 12

    within ".date-2010-01" do
      within "#deliverable-labor" do
        fill_in "hrs", :with => '20'
        fill_in "$", :with => '2000'
      end
      
      within "#deliverable-overhead" do
        fill_in "hrs", :with => '100'
        fill_in "$", :with => '100'
      end
    end

    click_button "Save"
    assert_response :success
    assert_template 'contracts/show'

    @labor_budgets = @retainer_deliverable.reload.labor_budgets
    assert_equal 12, @labor_budgets.length
    @labor_budgets.each do |labor_budget|
      if labor_budget.year == 2010 && labor_budget.month == 1

        # Specific month's budget updated?
        assert_equal 20.0, labor_budget.hours
        assert_equal 2000.0, labor_budget.budget

      else

        assert_equal 10.0, labor_budget.hours
        assert_equal 1000.0, labor_budget.budget

      end
    end
    
    @overhead_budgets = @retainer_deliverable.reload.overhead_budgets
    assert_equal 12, @overhead_budgets.length
    @overhead_budgets.each do |overhead_budget|
      if overhead_budget.year == 2010 && overhead_budget.month == 1

        # Specific month's budget updated?
        assert_equal 100.0, overhead_budget.hours
        assert_equal 100.0, overhead_budget.budget

      else

        assert_equal 10.0, overhead_budget.hours
        assert_equal 1000.0, overhead_budget.budget

      end
    end

  end

  should "allow extending a Retainer's start and end months" do
    labor_budget_hours_1 = 10
    labor_budget_hours_2 = 20
    labor_budget_amount_1 = 1000
    labor_budget_amount_2 = 2000
    overhead_budget_hours_1 = 10
    overhead_budget_hours_2 = 20
    overhead_budget_amount_1 = 1000
    overhead_budget_amount_2 = 2000
    
    
    @retainer_deliverable = RetainerDeliverable.spawn(:contract => @contract, :manager => @manager, :title => "Retainer")
    @retainer_deliverable.labor_budgets << @labor_budget = LaborBudget.spawn(:deliverable => @retainer_deliverable, :budget => labor_budget_amount_1, :hours => labor_budget_hours_1)
    @retainer_deliverable.labor_budgets << @labor_budget = LaborBudget.spawn(:deliverable => @retainer_deliverable, :budget => labor_budget_amount_2, :hours => labor_budget_hours_2)
    @retainer_deliverable.overhead_budgets << @overhead_budget = OverheadBudget.spawn(:deliverable => @retainer_deliverable, :budget => overhead_budget_amount_1, :hours => overhead_budget_hours_1)
    @retainer_deliverable.overhead_budgets << @overhead_budget = OverheadBudget.spawn(:deliverable => @retainer_deliverable, :budget => overhead_budget_amount_2, :hours => overhead_budget_hours_2)
    @retainer_deliverable.start_date = '2010-01-01'
    @retainer_deliverable.end_date = '2010-12-31'
    @retainer_deliverable.save!
    assert_equal 12, @retainer_deliverable.months.length
    assert_equal 24, @retainer_deliverable.reload.labor_budgets.count # 12 months * 2 records
    assert_equal 24, @retainer_deliverable.reload.overhead_budgets.count # 12 months * 2 records

    @first_labor_budget = @retainer_deliverable.labor_budgets.first
    @first_overhead_budget = @retainer_deliverable.overhead_budgets.first
    @last_labor_budget = @retainer_deliverable.labor_budgets.last
    @last_overhead_budget = @retainer_deliverable.overhead_budgets.last
    
    visit_contract_page(@contract)
    click_link_within "#deliverable_details_#{@retainer_deliverable.id}", 'Edit'
    assert_response :success
    assert_template 'deliverables/edit'

    # Extend the period
    fill_in "Start", :with => '2009-01-13' # 12 new months
    fill_in "End Date", :with => '2011-12-01' # 12 new months
    click_button "Save"
    assert_response :success
    assert_template 'contracts/show'

    @retainer_deliverable.reload
    
    assert_equal 36, @retainer_deliverable.months.length

    @labor_budgets = @retainer_deliverable.reload.labor_budgets
    assert_equal 72, @labor_budgets.length # 36 months * 2 records

    @labor_budgets_for_2009 = @labor_budgets.select {|l| l.year == 2009 }
    @labor_budgets_for_2010 = @labor_budgets.select {|l| l.year == 2010 }
    @labor_budgets_for_2011 = @labor_budgets.select {|l| l.year == 2011 }

    assert_equal 24, @labor_budgets_for_2009.length
    assert_equal 24, @labor_budgets_for_2010.length
    assert_equal 24, @labor_budgets_for_2011.length

    @labor_budgets_for_2009.each do |labor_budget|
      assert_equal 2009, labor_budget.year
      assert [labor_budget_hours_1, labor_budget_hours_2].include?(labor_budget.hours), "Extended labor budget hours not matching template budget"
      assert [labor_budget_amount_1, labor_budget_amount_2].include?(labor_budget.budget), "Extended labor budget dollars not matching template budget"
    end

    @labor_budgets_for_2010.each do |labor_budget|
      assert_equal 2010, labor_budget.year
      assert [labor_budget_hours_1, labor_budget_hours_2].include?(labor_budget.hours), "Extended labor budget hours not matching template budget"
      assert [labor_budget_amount_1, labor_budget_amount_2].include?(labor_budget.budget), "Extended labor budget dollars not matching template budget"
    end

    @labor_budgets_for_2011.each do |labor_budget|
      assert_equal 2011, labor_budget.year
      assert [labor_budget_hours_1, labor_budget_hours_2].include?(labor_budget.hours), "Extended labor budget hours not matching template budget"
      assert [labor_budget_amount_1, labor_budget_amount_2].include?(labor_budget.budget), "Extended labor budget dollars not matching template budget"
    end

    @overhead_budgets = @retainer_deliverable.reload.overhead_budgets
    assert_equal 72, @overhead_budgets.length # 36 months * 2 records

    @overhead_budgets_for_2009 = @overhead_budgets.select {|l| l.year == 2009 }
    @overhead_budgets_for_2010 = @overhead_budgets.select {|l| l.year == 2010 }
    @overhead_budgets_for_2011 = @overhead_budgets.select {|l| l.year == 2011 }

    assert_equal 24, @overhead_budgets_for_2009.length
    assert_equal 24, @overhead_budgets_for_2010.length
    assert_equal 24, @overhead_budgets_for_2011.length

    @overhead_budgets_for_2009.each do |overhead_budget|
      assert_equal 2009, overhead_budget.year
      assert [overhead_budget_hours_1, overhead_budget_hours_2].include?(overhead_budget.hours), "Extended overhead budget hours not matching template budget"
      assert [overhead_budget_amount_1, overhead_budget_amount_2].include?(overhead_budget.budget), "Extended overhead budget dollars not matching template budget"
    end

    @overhead_budgets_for_2010.each do |overhead_budget|
      assert_equal 2010, overhead_budget.year
      assert [overhead_budget_hours_1, overhead_budget_hours_2].include?(overhead_budget.hours), "Extended overhead budget hours not matching template budget"
      assert [overhead_budget_amount_1, overhead_budget_amount_2].include?(overhead_budget.budget), "Extended overhead budget dollars not matching template budget"
    end

    @overhead_budgets_for_2011.each do |overhead_budget|
      assert_equal 2011, overhead_budget.year
      assert [overhead_budget_hours_1, overhead_budget_hours_2].include?(overhead_budget.hours), "Extended overhead budget hours not matching template budget"
      assert [overhead_budget_amount_1, overhead_budget_amount_2].include?(overhead_budget.budget), "Extended overhead budget dollars not matching template budget"
    end

  end
end
