require 'test_helper'

class ContractsShowTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project)
  end

  should "allow any user to view the contract" do
    visit_contracts_for_project(@project)
    click_link @contract.id
    assert_response :success
    assert_template 'contracts/show'
    assert_equal "/projects/main/contracts/#{@contract.id}", current_url

    assert_select "div#contract_#{@contract.id}.contract" do
      assert_select 'h2', :text => @contract.name
    end
  end

  should "have a link to create a new deliverable" do
    visit_contracts_for_project(@project)
    click_link @contract.id
    assert_response :success

    assert_select "a#new-deliverable", :text => /Add New/
    click_link "Add New"
    assert_response :success
    assert_template 'deliverables/new'
    assert_equal "/projects/main/contracts/#{@contract.id}/deliverables/new", current_url
  end

  should "show a list of deliverables for the contract" do
    @manager = User.generate!

    @deliverable1 = FixedDeliverable.generate!(:contract => @contract, :manager => @manager)
    @deliverable2 = FixedDeliverable.generate!(:contract => @contract, :manager => @manager)
    visit_contract_page(@contract)

    assert_select "table#deliverables" do
      [@deliverable1, @deliverable2].each do |deliverable|
        assert_select "td.end-date", :text => /#{format_date(deliverable.end_date)}/
        assert_select "td.type", :text => "F"
        assert_select "td.title", :text => /#{deliverable.title}/
        assert_select "td.manager", :text => /#{deliverable.manager.name}/
      end
    end

  end
end
