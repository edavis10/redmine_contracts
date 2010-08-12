require 'test_helper'

class ContractsNewTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    PaymentTerm.generate!(:type => 'PaymentTerm', :name => 'Net 15')
    PaymentTerm.generate!(:type => 'PaymentTerm', :name => 'Net 30')
  end

  should "allow any user to open the new contracts form" do
    visit_contracts_for_project(@project)
    click_link 'New Contract'
    assert_response :success

    assert_select "form#new_contract"
  end

  should "create a new contract" do
    @account_executive = User.generate!
    @role = Role.generate!
    User.add_to_project(@account_executive, @project, @role)

    visit_contracts_for_project(@project)
    click_link 'New Contract'
    assert_response :success

    fill_in "Name", :with => 'A New Contract'
    select @account_executive.name, :from => "Account Executive"
    fill_in "Start", :with => '2010-01-01'
    fill_in "End Date", :with => '2010-12-31'
    select "Net 30", :from => "Payment Terms"

    click_button "Save Contract"

    assert_response :success
    assert_template 'contracts/show'

    @contract = Contract.last
    assert_equal "A New Contract", @contract.name
    assert_equal @account_executive, @contract.account_executive
    assert_equal '2010-01-01', @contract.start_date.to_s
    assert_equal '2010-12-31', @contract.end_date.to_s
    assert_equal 'Net 30', @contract.payment_term.name
    
  end
end
