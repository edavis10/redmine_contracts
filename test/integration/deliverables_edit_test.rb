require 'test_helper'

class DeliverablesEditTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project, :name => 'A Contract', :payment_terms => 'net_15')
    @manager = User.generate!
    @role = Role.generate!
    User.add_to_project(@manager, @project, @role)
    @deliverable = FixedDeliverable.generate!(:contract => @contract, :manager => @manager, :title => 'The Title')
  end

  should "allow any user to edit the deliverable" do
    visit_contract_page(@contract)
    click_link_within "#fixed_deliverable_#{@deliverable.id}", 'Edit'
    assert_response :success
    assert_template 'deliverables/edit'

    assert_select "form#edit_fixed_deliverable_#{@deliverable.id}" do
      assert_select "input#fixed_deliverable_title[value=?]", /#{@deliverable.title}/
      assert_select "select#fixed_deliverable_type" do
        assert_select "option[selected=selected][value=FixedDeliverable]"
      end
    end

    fill_in "Title", :with => 'An updated title'
    check "Feature Sign Off"
    check "Warranty Sign Off"
    click_button "Save"

    assert_response :success
    assert_template 'contracts/show'

    assert_equal "An updated title", @deliverable.reload.title
    assert @deliverable.reload.warranty_sign_off?
    assert @deliverable.reload.feature_sign_off?

  end
end
