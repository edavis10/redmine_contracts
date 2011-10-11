require 'test_helper'

class DeliverablesEditTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project, :name => 'A Contract')
    @manager = User.generate!
    @role = Role.generate!
    User.add_to_project(@manager, @project, @role)
    @fixed_deliverable = FixedDeliverable.generate!(:contract => @contract, :manager => @manager, :title => 'The Title', :notes => "", :feature_sign_off => false, :warranty_sign_off => false)
    @hourly_deliverable = HourlyDeliverable.generate!(:contract => @contract, :manager => @manager, :title => 'An Hourly')
    
    @user = User.generate_user_with_permission_to_manage_budget(:project => @project)
    configure_overhead_plugin
    
    login_as(@user.login, 'contracts')
  end

  should "block anonymous users from editing the deliverable" do
    logout
    visit "/projects/#{@project.identifier}/contracts/#{@contract.id}/deliverables/#{@fixed_deliverable.id}"

    assert_requires_login
  end
  
  should "block unauthorized users from editing the deliverable" do
    logout

    @user = User.generate!(:password => 'test', :password_confirmation => 'test')
    login_as(@user.login, 'test')
    
    visit "/projects/#{@project.identifier}/contracts/#{@contract.id}/deliverables/#{@fixed_deliverable.id}"
    
    assert_forbidden
  end

  should "allow authorized users to edit the Fixed deliverable" do
    visit_contract_page(@contract)
    click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
    assert_response :success
    assert_template 'deliverables/edit'

    assert_select "form#edit_fixed_deliverable_#{@fixed_deliverable.id}" do
      assert_select "input#fixed_deliverable_title[value=?]", /#{@fixed_deliverable.title}/
    end

    assert_select "select#fixed_deliverable_type", :count => 0 # Not editable

    within("#deliverable-details") do
      fill_in "Title", :with => 'An updated title'
      select "Locked", :from => "Status"
      check "Feature Sign Off"
      check "Warranty Sign Off"
    end
    click_button "Save"

    assert_response :success
    assert_template 'contracts/show'

    assert_equal "An updated title", @fixed_deliverable.reload.title
    assert_equal "FixedDeliverable", @fixed_deliverable.reload.type
    assert @fixed_deliverable.reload.warranty_sign_off?
    assert @fixed_deliverable.reload.feature_sign_off?
    assert_equal "locked", @fixed_deliverable.reload.status

  end

  should "allow authorized users to edit the Hourly deliverable" do
    visit_contract_page(@contract)
    click_link_within "#deliverable_details_#{@hourly_deliverable.id}", 'Edit'
    assert_response :success
    assert_template 'deliverables/edit'

    assert_select "form#edit_hourly_deliverable_#{@hourly_deliverable.id}" do
      assert_select "input#hourly_deliverable_title[value=?]", /#{@hourly_deliverable.title}/
    end

    assert_select "select#hourly_deliverable_type", :count => 0 # Not editable
    
    within("#deliverable-details") do
      fill_in "Title", :with => 'An updated title'
      select "Locked", :from => "Status"
      check "Feature Sign Off"
      check "Warranty Sign Off"
    end

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
    assert_equal "locked", @hourly_deliverable.reload.status

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
    @retainer_deliverable.fixed_budgets << @fixed_budget = FixedBudget.spawn(:deliverable => @retainer_deliverable, :title => 'Printing supplies', :budget => 100, :markup => 0)
    
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

      within "#deliverable-fixed" do
        fill_in "title", :with => 'Flight to NYC'
        fill_in "budget", :with => '$600'
        fill_in "markup", :with => '50%'
        fill_in "description", :with => 'Need to fly to NYC for the week'
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

    @fixed_budgets = @retainer_deliverable.reload.fixed_budgets
    assert_equal 12, @fixed_budgets.length
    @fixed_budgets.each do |fixed_budget|
      if fixed_budget.year == 2010 && fixed_budget.month == 1

        # Specific month's budget updated?
        assert_equal 600, fixed_budget.budget
        assert_equal '50%', fixed_budget.markup
        assert_equal 300, fixed_budget.markup_value

      else

        assert_equal 100, fixed_budget.budget
        assert_equal '$0.00', fixed_budget.markup

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
    @retainer_deliverable.fixed_budgets << @fixed_budget = FixedBudget.spawn(:deliverable => @retainer_deliverable, :title => 'Printing supplies', :budget => 100, :markup => 0)
    @retainer_deliverable.start_date = '2010-01-01'
    @retainer_deliverable.end_date = '2010-12-31'
    @retainer_deliverable.save!
    assert_equal 12, @retainer_deliverable.months.length
    assert_equal 24, @retainer_deliverable.reload.labor_budgets.count # 12 months * 2 records
    assert_equal 24, @retainer_deliverable.reload.overhead_budgets.count # 12 months * 2 records

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

    @fixed_budgets = @retainer_deliverable.reload.fixed_budgets
    assert_equal 36, @fixed_budgets.length # 36 months * 1 record
    
    @fixed_budgets_for_2009 = @fixed_budgets.select {|l| l.year == 2009 }
    @fixed_budgets_for_2010 = @fixed_budgets.select {|l| l.year == 2010 }
    @fixed_budgets_for_2011 = @fixed_budgets.select {|l| l.year == 2011 }

    assert_equal 12, @fixed_budgets_for_2009.length
    assert_equal 12, @fixed_budgets_for_2010.length
    assert_equal 12, @fixed_budgets_for_2011.length

  end

  should "allow shrinking a Retainer's start and end months" do
    @retainer_deliverable = RetainerDeliverable.spawn(:contract => @contract, :manager => @manager, :title => "Retainer")
    @retainer_deliverable.labor_budgets << @labor_budget = LaborBudget.spawn(:deliverable => @retainer_deliverable, :budget => 1000, :hours => 10)
    @retainer_deliverable.labor_budgets << @labor_budget = LaborBudget.spawn(:deliverable => @retainer_deliverable, :budget => 2000, :hours => 20)
    @retainer_deliverable.overhead_budgets << @overhead_budget = OverheadBudget.spawn(:deliverable => @retainer_deliverable, :budget => 1000, :hours => 10)
    @retainer_deliverable.overhead_budgets << @overhead_budget = OverheadBudget.spawn(:deliverable => @retainer_deliverable, :budget => 2000, :hours => 20)
    @retainer_deliverable.fixed_budgets << @fixed_budget = FixedBudget.spawn(:deliverable => @retainer_deliverable, :title => 'Printing supplies', :budget => 100, :markup => 0)
    @retainer_deliverable.start_date = '2010-01-01'
    @retainer_deliverable.end_date = '2010-12-31'
    @retainer_deliverable.save!
    assert_equal 12, @retainer_deliverable.months.length
    assert_equal 24, @retainer_deliverable.reload.labor_budgets.count # 12 months * 2 records
    assert_equal 24, @retainer_deliverable.reload.overhead_budgets.count # 12 months * 2 records

    visit_contract_page(@contract)
    click_link_within "#deliverable_details_#{@retainer_deliverable.id}", 'Edit'
    assert_response :success
    assert_template 'deliverables/edit'

    # Shrink the period to only 6 months
    fill_in "Start", :with => '2010-02-13'
    fill_in "End Date", :with => '2010-07-01'
    click_button "Save"
    assert_response :success
    assert_template 'contracts/show'

    @retainer_deliverable.reload
    
    assert_equal 6, @retainer_deliverable.months.length

    @labor_budgets = @retainer_deliverable.reload.labor_budgets
    assert_equal 12, @labor_budgets.length # 6 months * 2 records

    @overhead_budgets = @retainer_deliverable.reload.overhead_budgets
    assert_equal 12, @overhead_budgets.length # 6 months * 2 records

    @fixed_budgets = @retainer_deliverable.reload.fixed_budgets
    assert_equal 6, @fixed_budgets.length # 6 months * 1 records

  end

  should "allow editing a Retainer's start and end months inside the current period" do
    @retainer_deliverable = RetainerDeliverable.spawn(:contract => @contract, :manager => @manager, :title => "Retainer")
    @retainer_deliverable.labor_budgets << @labor_budget = LaborBudget.spawn(:deliverable => @retainer_deliverable, :budget => 1000, :hours => 10)
    @retainer_deliverable.labor_budgets << @labor_budget = LaborBudget.spawn(:deliverable => @retainer_deliverable, :budget => 2000, :hours => 20)
    @retainer_deliverable.overhead_budgets << @overhead_budget = OverheadBudget.spawn(:deliverable => @retainer_deliverable, :budget => 1000, :hours => 10)
    @retainer_deliverable.overhead_budgets << @overhead_budget = OverheadBudget.spawn(:deliverable => @retainer_deliverable, :budget => 2000, :hours => 20)
    @retainer_deliverable.start_date = '2010-01-01'
    @retainer_deliverable.end_date = '2010-12-31'
    @retainer_deliverable.save!
    assert_equal 12, @retainer_deliverable.months.length
    assert_equal 24, @retainer_deliverable.reload.labor_budgets.count # 12 months * 2 records
    assert_equal 24, @retainer_deliverable.reload.overhead_budgets.count # 12 months * 2 records

    visit_contract_page(@contract)
    click_link_within "#deliverable_details_#{@retainer_deliverable.id}", 'Edit'
    assert_response :success
    assert_template 'deliverables/edit'

    # Edit the dates without changing the period
    fill_in "Start", :with => '2010-01-13'
    fill_in "End Date", :with => '2010-12-01'
    click_button "Save"
    assert_response :success
    assert_template 'contracts/show'

    @retainer_deliverable.reload
    
    assert_equal 12, @retainer_deliverable.months.length

    @labor_budgets = @retainer_deliverable.reload.labor_budgets
    assert_equal 24, @labor_budgets.length # 12 months * 2 records

    @overhead_budgets = @retainer_deliverable.reload.overhead_budgets
    assert_equal 24, @overhead_budgets.length # 12 months * 2 records

  end

  should "show empty budget fields for a Retainer that has missing budgets" do
    @retainer_deliverable = RetainerDeliverable.spawn(:contract => @contract, :manager => @manager, :title => "Retainer")
    @retainer_deliverable.start_date = '2010-01-01'
    @retainer_deliverable.end_date = '2010-03-31'
    @retainer_deliverable.save!
    assert_equal 3, @retainer_deliverable.months.length
    assert_equal 0, @retainer_deliverable.reload.labor_budgets.count # 3 months * 0 records
    assert_equal 0, @retainer_deliverable.reload.overhead_budgets.count # 3 months * 0 records

    visit_contract_page(@contract)
    click_link_within "#deliverable_details_#{@retainer_deliverable.id}", 'Edit'
    assert_response :success
    assert_template 'deliverables/edit'

    # Should show inputs:
    # * labor hidden year
    # * labor hidden month
    # * labor hours
    # * labor amount
    # * labor deleted (hidden)
    # * overhead hidden year
    # * overhead hidden month
    # * overhead hours
    # * overhead amount
    # * overhead deleted (hidden)
    # * fixed hidden year
    # * fixed hidden month
    # * fixed title
    # * fixed budget
    # * fixed markup
    # * fixed paid checkbox
    # * fixed paid hidden field
    # * total (hidden)
    assert_select ".date-2010-01" do
      assert_select "input", :count => 18
      assert_select "textarea.wiki-edit", :count => 1 # Fixed description
    end


    within ".date-2010-01" do
      within "#deliverable-labor" do
        fill_in "hrs", :with => '20'
        fill_in "$", :with => '2000'
      end
      
      within "#deliverable-overhead" do
        fill_in "hrs", :with => '100'
        fill_in "$", :with => '100'
      end

      within "#deliverable-fixed" do
        fill_in "title", :with => 'Flight to NYC'
        fill_in "budget", :with => '$600'
        fill_in "markup", :with => '50%'
        fill_in "description", :with => 'Need to fly to NYC for the week'
      end

    end

    click_button "Save"
    assert_response :success
    assert_template 'contracts/show'

    @retainer_deliverable.reload
    
    assert_equal 3, @retainer_deliverable.labor_budgets.count
    assert_equal [20, nil, nil], @retainer_deliverable.labor_budgets.collect(&:hours)
    assert_equal [2000, nil, nil], @retainer_deliverable.labor_budgets.collect(&:budget)

    assert_equal 3, @retainer_deliverable.overhead_budgets.count
    assert_equal [100, nil, nil], @retainer_deliverable.overhead_budgets.collect(&:hours)
    assert_equal [100, nil, nil], @retainer_deliverable.overhead_budgets.collect(&:budget)

    assert_equal 3, @retainer_deliverable.fixed_budgets.count
    assert_equal [600, nil, nil], @retainer_deliverable.fixed_budgets.collect(&:budget)
  end

  context "locked deliverable" do
    setup do
      assert @fixed_deliverable.lock!
    end
    
    should "block edits to locked deliverables" do
      visit_contract_page(@contract)
      click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
      assert_response :success

      within("#deliverable-details") do
        fill_in "Title", :with => 'An updated title'
      end

      click_button "Save"

      assert_response :success
      assert_template 'deliverables/edit'

      assert_not_equal "An updated title", @fixed_deliverable.reload.title
    end

    should "block edits to locked deliverables even when status changes to closed" do
      visit_contract_page(@contract)
      click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
      assert_response :success

      within("#deliverable-details") do
        fill_in "Title", :with => 'An updated title'
        select "Closed", :from => "Status"
      end

      click_button "Save"

      assert_response :success
      assert_template 'deliverables/edit'

      assert_not_equal "An updated title", @fixed_deliverable.reload.title
      assert @fixed_deliverable.reload.locked?
    end
    
    should "be allowed to change the status on a locked deliverables to open" do
      visit_contract_page(@contract)
      click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
      assert_response :success

      within("#deliverable-details") do
        select "Open", :from => "Status"
      end

      click_button "Save"

      assert_response :success
      assert_template 'contracts/show'

      assert @fixed_deliverable.reload.open?
    end

    should "be allowed to change the status on a locked deliverables to closed" do
      visit_contract_page(@contract)
      click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
      assert_response :success

      within("#deliverable-details") do
        select "Closed", :from => "Status"
      end

      click_button "Save"

      assert_response :success
      assert_template 'contracts/show'

      assert @fixed_deliverable.reload.closed?
    end
    
  end

  context "closed deliverable" do
    setup do
      assert @fixed_deliverable.close!
    end
    
    should "block edits to closed deliverables" do
      visit_contract_page(@contract)
      click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
      assert_response :success

      within("#deliverable-details") do
        fill_in "Title", :with => 'An updated title'
      end

      click_button "Save"

      assert_response :success
      assert_template 'deliverables/edit'

      assert_not_equal "An updated title", @fixed_deliverable.reload.title
    end

    should "block edits to closed deliverables even when the status is changed to locked" do
      visit_contract_page(@contract)
      click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
      assert_response :success

      within("#deliverable-details") do
        fill_in "Title", :with => 'An updated title'
        select "Locked", :from => "Status"
      end

      click_button "Save"

      assert_response :success
      assert_template 'deliverables/edit'

      assert_not_equal "An updated title", @fixed_deliverable.reload.title
      assert @fixed_deliverable.reload.closed?
    end

    should "be allowed to change the status on a closed deliverables to open" do
      visit_contract_page(@contract)
      click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
      assert_response :success

      within("#deliverable-details") do
        select "Open", :from => "Status"
      end

      click_button "Save"

      assert_response :success
      assert_template 'contracts/show'

      assert @fixed_deliverable.reload.open?
    end

    should "be allowed to change the status on a closed deliverables to Locked" do
      visit_contract_page(@contract)
      click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
      assert_response :success

      within("#deliverable-details") do
        select "Locked", :from => "Status"
      end

      click_button "Save"

      assert_response :success
      assert_template 'contracts/show'

      assert @fixed_deliverable.reload.locked?
    end
  end
  
  context "a Deliverable on a locked Contract" do
    setup do
      assert @contract.lock!
    end
    
    should "be blocked from editing" do
      visit_contract_page(@contract)
      click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
      assert_response :success

      within("#deliverable-details") do
        fill_in "Title", :with => 'An updated title'
      end

      click_button "Save"

      assert_response :success
      assert_template 'deliverables/edit'

      assert_not_equal "An updated title", @fixed_deliverable.reload.title
    end
    
    should "allow status only changes" do
      visit_contract_page(@contract)
      click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
      assert_response :success

      within("#deliverable-details") do
        select "Locked", :from => "Status"
      end

      click_button "Save"

      assert_response :success
      assert_template 'contracts/show'

      assert @fixed_deliverable.reload.locked?
    end
    
  end
  
  context "a Deliverable on a closed Contract" do
    setup do
      assert @contract.close!
    end
    
    should "be blocked from editing" do
      visit_contract_page(@contract)
      click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
      assert_response :success

      within("#deliverable-details") do
        fill_in "Title", :with => 'An updated title'
      end

      click_button "Save"

      assert_response :success
      assert_template 'deliverables/edit'

      assert_not_equal "An updated title", @fixed_deliverable.reload.title
    end
    
    should "allow status only changes" do
      visit_contract_page(@contract)
      click_link_within "#deliverable_details_#{@fixed_deliverable.id}", 'Edit'
      assert_response :success

      within("#deliverable-details") do
        select "Locked", :from => "Status"
      end

      click_button "Save"

      assert_response :success
      assert_template 'contracts/show'

      assert @fixed_deliverable.reload.locked?
    end
    
  end

end
