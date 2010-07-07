require 'test_helper'

class DeliverablesDeleteTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project, :name => 'A Contract', :payment_terms => 'net_15')
    @manager = User.generate!
    @deliverable = FixedDeliverable.generate!(:contract => @contract, :manager => @manager)
  end

  should "allow anyone to delete the deliverable" do
    visit_contract_page(@contract)

    click_link_within "#fixed_deliverable_#{@deliverable.id}", 'Delete'
    assert_response :success
    assert_template 'contracts/show'

    assert_nil Deliverable.find_by_id(@deliverable.id), "Deliverable not deleted"
  end
end