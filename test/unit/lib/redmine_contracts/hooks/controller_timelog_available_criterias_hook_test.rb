require File.dirname(__FILE__) + '/../../../../test_helper'

class RedmineContracts::Hooks::ControllerTimelogAvailableCriteriasTest < ActionController::TestCase
  include Redmine::Hook::Helper

  def controller
    @controller ||= ApplicationController.new
    @controller.response ||= ActionController::TestResponse.new
    @controller
  end

  def request
    @request ||= ActionController::TestRequest.new
  end
  
  def hook(args={})
    call_hook :controller_timelog_available_criterias, args
  end

  def context
    @context ||= {
      :available_criterias => {"existing" => {:label => 'existing'}}
    }
  end

  context "#controller_timelog_available_criterias" do
    should "return an empty string" do
      @response.body = hook(context)
      assert @response.body.blank?
    end

    context "Deliverables" do
      should "add a deliverable_id to the available criterias" do
        @response.body = hook(context)
        assert context[:available_criterias]['deliverable_id']
      end
      
      should "add the deliverable sql to the available criterias" do
        @response.body = hook(context)
        assert "issues.deliverable_id", context[:available_criterias]['deliverable_id'][:sql]
      end

      should "add the deliverable Class to the available criterias" do
        @response.body = hook(context)
        assert Deliverable, context[:available_criterias]['deliverable_id'][:klass]
      end

      should "add the deliverable label to the available criterias" do
        @response.body = hook(context)
        assert :field_deliverable, context[:available_criterias]['deliverable_id'][:label]
      end
    end

    context "Contracts" do
      should "add a contract_id to the available criterias" do
        @response.body = hook(context)
        assert context[:available_criterias]['contract_id']
      end
      
      should "add the contact sql to the available criterias" do
        @response.body = hook(context)
        assert "issues.deliverable_id", context[:available_criterias]['contract_id'][:sql]
      end

      should "add the deliverable Class to the available criterias" do
        @response.body = hook(context)
        assert Contract, context[:available_criterias]['contract_id'][:klass]
      end

      should "add the deliverable label to the available criterias" do
        @response.body = hook(context)
        assert :field_contract, context[:available_criterias]['contract_id'][:label]
      end
    end

  end
end
