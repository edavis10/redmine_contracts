require 'test_helper'

class DeliverablesNewTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project)
    @user = User.generate_user_with_permission_to_manage_budget(:project => @project)
    
    login_as(@user.login, 'contracts')
  end

  should "block anonymous users from opening the new deliverable form" do
    logout
    visit "/projects/#{@project.identifier}/contracts/#{@contract.id}/deliverables/new"

    assert_requires_login
  end
  
  should "block unauthorized users from opening the new deliverable form" do
    logout

    @user = User.generate!(:password => 'test', :password_confirmation => 'test')
    login_as(@user.login, 'test')
    
    visit "/projects/#{@project.identifier}/contracts/#{@contract.id}/deliverables/new"

    assert_forbidden
  end

  should "allow authorized users open the new deliverable form" do
    visit_contract_page(@contract)
    click_link 'Add New'
    assert_response :success
    assert_template 'deliverables/new'

    assert_select "form#new_deliverable"
  end

  should "show all members on the project as available managers" do
    @member1 = User.generate!.reload
    @member2 = User.generate!.reload
    @member3 = User.generate!.reload
    @nonmember1 = User.generate!

    @role = Role.generate!
    User.add_to_project(@member1, @project, @role)
    User.add_to_project(@member2, @project, @role)
    User.add_to_project(@member3, @project, @role)

    visit_contract_page(@contract)
    click_link 'Add New'
    assert_response :success

    assert_select "select#deliverable_manager_id" do
      assert_select "option", :text => @member1.to_s
      assert_select "option", :text => @member2.to_s
      assert_select "option", :text => @member3.to_s
    end

    assert_select "select#deliverable_manager_id option", :text => @nonmember1.to_s, :count => 0
  end

  should "create a new Fixed deliverable" do
    @manager = User.generate!
    @role = Role.generate!
    User.add_to_project(@manager, @project, @role)

    visit_contract_page(@contract)
    click_link 'Add New'
    assert_response :success

    within("#deliverable-details") do
      fill_in "Title", :with => 'A New Deliverable'
      select "Fixed", :from => "Type"
      select @manager.name, :from => "Manager"
      fill_in "Start", :with => '2010-01-01'
      fill_in "End Date", :with => '2010-12-31'
      fill_in "Notes", :with => 'Some notes on the deliverable'
    end
    
    fill_in "Total", :with => '1,000.00'
    # TODO: webrat can't trigger DOM events so it can't appear
    # assert js("jQuery('#deliverable_total').is(':visible')"), "Total is hidden when it should be visible"

    click_button "Save"

    assert_response :success
    assert_template 'contracts/show'

    @deliverable = Deliverable.last
    assert_equal "A New Deliverable", @deliverable.title
    assert_equal @contract, @deliverable.contract
    assert_equal "FixedDeliverable", @deliverable.type
    assert_equal '2010-01-01', @deliverable.start_date.to_s
    assert_equal '2010-12-31', @deliverable.end_date.to_s
    assert_equal @manager, @deliverable.manager
    assert_equal 1000.0, @deliverable.total.to_f
  end

  should "create a new Hourly deliverable" do
    @manager = User.generate!
    @role = Role.generate!
    User.add_to_project(@manager, @project, @role)

    visit_contract_page(@contract)
    click_link 'Add New'
    assert_response :success

    within("#deliverable-details") do
      fill_in "Title", :with => 'A New Deliverable'
      select "Hourly", :from => "Type"
      select @manager.name, :from => "Manager"
      fill_in "Start", :with => '2010-01-01'
      fill_in "End Date", :with => '2010-12-31'
      fill_in "Notes", :with => 'Some notes on the deliverable'
    end
    fill_in "Total", :with => '1,000.00'

    # # Hide and clear the total
    # assert js("jQuery('#deliverable_total_input').is(':hidden')"),
    #        "Total is visible when it should be hidden"
    
    click_button "Save"

    assert_response :success
    assert_template 'contracts/show'

    @deliverable = Deliverable.last
    assert_equal "A New Deliverable", @deliverable.title
    assert_equal @contract, @deliverable.contract
    assert_equal "HourlyDeliverable", @deliverable.type
    assert_equal '2010-01-01', @deliverable.start_date.to_s
    assert_equal '2010-12-31', @deliverable.end_date.to_s
    assert_equal @manager, @deliverable.manager

  end

  should "create a new Retainer deliverable" do
    @manager = User.generate!
    @role = Role.generate!
    User.add_to_project(@manager, @project, @role)

    visit_contract_page(@contract)
    click_link 'Add New'
    assert_response :success

    within("#deliverable-details") do
      fill_in "Title", :with => 'A New Deliverable'
      select "Retainer", :from => "Type"
      select @manager.name, :from => "Manager"
      fill_in "Start", :with => '2010-01-01'
      fill_in "End Date", :with => '2010-12-31'
      fill_in "Notes", :with => 'Some notes on the deliverable'
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

    @deliverable = Deliverable.last
    assert_equal "A New Deliverable", @deliverable.title
    assert_equal @contract, @deliverable.contract
    assert_equal "RetainerDeliverable", @deliverable.type
    assert_equal '2010-01-01', @deliverable.start_date.to_s
    assert_equal '2010-12-31', @deliverable.end_date.to_s
    assert_equal @manager, @deliverable.manager

    # Budget items, one per month
    labor_budgets = @deliverable.labor_budgets
    assert_equal 12, labor_budgets.length
    
    labor_budgets.each do |budget|
      assert_equal 2000, budget.budget
      assert_equal 20, budget.hours
    end

    # Budget dates
    labor_budgets.each do |budget|
      assert_equal 2010, budget.year
    end
    (1..12).each do |month_number|
      assert_equal 1, labor_budgets.select {|b| b.month == month_number}.length
    end

    overhead_budgets = @deliverable.overhead_budgets
    assert_equal 12, overhead_budgets.length
    
    overhead_budgets.each do |budget|
      assert_equal 1000, budget.budget
      assert_equal 10, budget.hours
    end

    # Budget dates
    overhead_budgets.each do |budget|
      assert_equal 2010, budget.year
    end
    (1..12).each do |month_number|
      assert_equal 1, overhead_budgets.select {|b| b.month == month_number}.length
    end
  end

  should "create new budget items for the deliverables" do
    @manager = User.generate!
    @role = Role.generate!
    User.add_to_project(@manager, @project, @role)

    visit_contract_page(@contract)
    click_link 'Add New'
    assert_response :success

    within("#deliverable-details") do
      fill_in "Title", :with => 'A New Deliverable'
      select "Hourly", :from => "Type"
      select @manager.name, :from => "Manager"
      fill_in "Start", :with => '2010-01-01'
      fill_in "End Date", :with => '2010-12-31'
      fill_in "Notes", :with => 'Some notes on the deliverable'
    end

    within("#deliverable-labor") do
      fill_in "hrs", :with => '20'
      fill_in "$", :with => '$2,000'
    end

    within("#deliverable-overhead") do
      fill_in "hrs", :with => '10'
      fill_in "$", :with => '$1,000'
    end

    within("#deliverable-fixed") do
      fill_in "title", :with => 'Flight to NYC'
      fill_in "budget", :with => '$600'
      fill_in "markup", :with => '50%'
      fill_in "description", :with => 'Need to fly to NYC for the week'
    end
    
    click_button "Save"

    assert_response :success
    assert_template 'contracts/show'

    @deliverable = Deliverable.last

    assert_equal 1, @deliverable.labor_budgets.count
    @labor_budget = @deliverable.labor_budgets.first
    assert_equal 20, @labor_budget.hours
    assert_equal 2000.0, @labor_budget.budget

    assert_equal 1, @deliverable.overhead_budgets.count
    @overhead_budget = @deliverable.overhead_budgets.first
    assert_equal 10, @overhead_budget.hours
    assert_equal 1000.0, @overhead_budget.budget

    assert_equal 1, @deliverable.fixed_budgets.count
    @fixed_budget = @deliverable.fixed_budgets.first
    assert_equal "Flight to NYC", @fixed_budget.title
    assert_equal 600, @fixed_budget.budget
    assert_equal "50%", @fixed_budget.markup
    assert_equal 300, @fixed_budget.markup_value # 600 * 50%
    
  end

end
