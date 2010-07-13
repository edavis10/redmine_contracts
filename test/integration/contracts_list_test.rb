require 'test_helper'

class ContractsListTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project)
    @contract2 = Contract.generate!(:project => @project)

    @other_project = Project.generate!(:identifier => 'other')
    @other_contract = Contract.generate!(:project => @other_project)
    [@project,
     @other_project,
     @contract,
     @contract2,
     @other_contract
    ].map {|c| c.reload }
  end

  should "allow any user to list the contracts on a project" do
    visit_contracts_for_project(@project)
  end

  should "list all contracts for the project" do
    visit_contracts_for_project(@project)

    assert_select "table#contracts" do
      [@contract, @contract2].each do |contract|
        assert_select "td.id", :text => /#{contract.id}/
        assert_select "td.name", :text => /#{contract.name}/
        assert_select "td.account-executive", :text => /#{contract.account_executive.name}/
        assert_select "td.end-date", :text => /#{format_date(contract.end_date)}/
        assert_select "td.total-budget"
      end
    end
    
  end

  should "not list contracts from other projects" do
    visit_contracts_for_project(@project)

    assert_select "table#contracts" do
      assert_select "td", :text => /#{@other_contract.name}/, :count => 0
    end
    
  end

end
