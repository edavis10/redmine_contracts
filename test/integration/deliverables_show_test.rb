require 'test_helper'

class DeliverablesShowTest < ActionController::IntegrationTest
  include Redmine::I18n
  
  def setup
    @project = Project.generate!(:identifier => 'main')
    @contract = Contract.generate!(:project => @project)
    @manager = User.generate!
    @deliverable = FixedDeliverable.generate!(:contract => @contract, :manager => @manager)
  end

  should "redirect to the contract page" do
    visit "/projects/#{@project.identifier}/contracts/#{@contract.id}/deliverables/#{@deliverable.id}"
    assert_response :success
    assert_template 'contracts/show'
    
  end
end
