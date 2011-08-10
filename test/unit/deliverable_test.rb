require File.dirname(__FILE__) + '/../test_helper'

class DeliverableTest < ActiveSupport::TestCase
  should_belong_to :contract
  should_belong_to :manager
  should_have_many :labor_budgets
  should_have_many :overhead_budgets
  should_have_many :fixed_budgets
  should_have_many :issues

  should_validate_presence_of :title
  should_validate_presence_of :type
  should_validate_presence_of :manager

  should_allow_values_for :status, "", nil, 'open', 'locked', 'closed'
  should_not_allow_values_for :status, "other", "things", "1"

  should "default status to open" do
    assert_equal "open", Deliverable.new.status
  end

  context "#total=" do
    should "strip dollar signs when writing" do
      d = Deliverable.new
      d.total = '$100.00'
      
      assert_equal 100.00, d.total.to_f
    end

    should "strip commas when writing" do
      d = Deliverable.new
      d.total = '20,100.00'
      
      assert_equal 20100.00, d.total.to_f
    end

    should "strip spaces when writing" do
      d = Deliverable.new
      d.total = '20 100.00'
      
      assert_equal 20100.00, d.total.to_f
    end
  end

  context "with a locked contract" do
    should "block creating a new deliverable" do
      contract = Contract.generate!(:status => "locked")
      deliverable = FixedDeliverable.spawn(:contract => contract)

      assert !deliverable.valid?
      assert deliverable.errors.on_base.include?("Can't create a deliverable on a locked contract")
    end

    should "block deleting a deliverable" do
      contract = Contract.generate!
      deliverable = FixedDeliverable.generate!(:contract => contract).reload
      assert contract.lock!

      assert_no_difference("Deliverable.count") do
        deliverable.destroy
      end
      
    end
  end

  context "with a closed contract" do
    should "block creating a new deliverable" do
      contract = Contract.generate!(:status => "closed")
      deliverable = FixedDeliverable.spawn(:contract => contract)

      assert !deliverable.valid?
      assert deliverable.errors.on_base.include?("Can't create a deliverable on a closed contract")
    end

    should "block deleting a deliverable" do
      contract = Contract.generate!
      deliverable = FixedDeliverable.generate!(:contract => contract).reload
      assert contract.close!

      assert_no_difference("Deliverable.count") do
        deliverable.destroy
      end
      
    end
  end
end
