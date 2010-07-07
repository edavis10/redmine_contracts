require 'test_helper'

class DeliverablesEditTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project, :name => 'A Contract', :payment_terms => 'net_15')
    @manager = User.generate!
    @role = Role.generate!
    User.add_to_project(@manager, @project, @role)
    @fixed_deliverable = FixedDeliverable.generate!(:contract => @contract, :manager => @manager, :title => 'The Title')
    @hourly_deliverable = HourlyDeliverable.generate!(:contract => @contract, :manager => @manager, :title => 'An Hourly')
    
  end

  should "allow any user to edit the Fixed deliverable" do
    visit_contract_page(@contract)
    click_link_within "#fixed_deliverable_#{@fixed_deliverable.id}", 'Edit'
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
    click_link_within "#hourly_deliverable_#{@hourly_deliverable.id}", 'Edit'
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

    fill_in "hrs", :with => '20'
    fill_in "$", :with => '$2,000'

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

  end
end
