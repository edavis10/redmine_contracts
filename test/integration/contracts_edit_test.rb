require 'test_helper'

class ContractsEditTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @account_executive = User.generate!
    @role = Role.generate!
    User.add_to_project(@account_executive, @project, @role)
    @contract = Contract.generate!(:project => @project, :name => 'A Contract', :payment_terms => 'net_15', :account_executive => @account_executive)
  end

  should "allow any user to edit the contract" do
    visit_contracts_for_project(@project)
    click_link @contract.id
    assert_response :success

    click_link 'Update'
    assert_response :success
    assert_template 'contracts/edit'

    assert_select "h2", :text => /#{@contract.name}/
    assert_select "form#edit_contract_#{@contract.id}.contract" do
      assert_select "input[value=?]", /#{@contract.name}/
      assert_select "select#contract_payment_terms" do
        assert_select "option[selected=selected][value=net_15]"
      end
    end

    fill_in "Name", :with => 'An updated name'
    click_button "Update Contract"

    assert_response :success
    assert_template 'contracts/show'

    assert_equal "An updated name", @contract.reload.name

  end
end
