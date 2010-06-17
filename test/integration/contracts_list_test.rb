require 'test_helper'

class ContractsListTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!
    @contract = Contract.generate!(:project => @project)
    @contract2 = Contract.generate!(:project => @project)
  end

  should "allow any user to list the contracts on a project" do
    visit_contracts_for_project(@project)
  end

  should "list all contracts for the project" do
    visit_contracts_for_project(@project)

    assert_select "table#contracts" do
      [@contract, @contract2].each do |contract|
        assert_select "td", :text => /#{contract.id}/
        assert_select "td", :text => /#{contract.name}/
        assert_select "td", :text => /#{contract.account_executive.name}/
        assert_select "td", :text => /#{format_date(contract.end_date)}/
      end
    end
    
  end

  should "not list contracts from other projects"

end
