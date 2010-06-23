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

  should "create a new Fixed deliverable" do
    @manager = User.generate!

    visit_contract_page(@contract)
    click_link 'Add New'
    assert_response :success

    fill_in "Title", :with => 'A New Deliverable'
    select "Fixed", :from => "Type"
    select @manager.name, :from => "Manager"
    fill_in "Start", :with => '2010-01-01'
    fill_in "End Date", :with => '2010-12-31'
    fill_in "Notes", :with => 'Some notes on the deliverable'

    click_button "Create Deliverable"

    assert_response :success
    assert_template 'contracts/show'

    @deliverable = Deliverable.last
    assert_equal "A New Deliverable", @deliverable.title
    assert_equal "FixedDeliverable", @deliverable.type
    assert_equal '2010-01-01', @deliverable.start_date.to_s
    assert_equal '2010-12-31', @deliverable.end_date.to_s
    assert_equal @manager, @deliverable.manager
  end
end
