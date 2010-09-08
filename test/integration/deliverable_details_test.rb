require 'test_helper'

class DeliverableDetailsShowTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main').reload
    @contract = Contract.generate!(:project => @project)
    @manager = User.generate!
    @deliverable1 = FixedDeliverable.generate!(:contract => @contract, :manager => @manager)
  end

  context "for a JS request" do
    should "render the details for the deliverable" do
      visit "/projects/#{@project.id}/contracts/#{@contract.id}/deliverables/#{@deliverable1.id}", :get, {:format => 'js', :as => 'deliverable_details_row'}

      assert_response :success
      assert_select ".deliverable_details_outer_wrapper_#{@deliverable1.id}"
      assert_select "table#deliverables", :count => 0 # Not the full table
      assert_select "tr#deliverable_details_#{@deliverable1.id}", :count => 0 # Not the wrapper tr

    end

  end
end
