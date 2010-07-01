require 'test_helper'

class DeliverablesNewTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project)
  end

  should "allow any user to open the new deliverable form" do
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

    fill_in "Title", :with => 'A New Deliverable'
    select "Fixed", :from => "Type"
    select @manager.name, :from => "Manager"
    fill_in "Start", :with => '2010-01-01'
    fill_in "End Date", :with => '2010-12-31'
    fill_in "Notes", :with => 'Some notes on the deliverable'
    fill_in "Total", :with => '1,000.00'

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
end
