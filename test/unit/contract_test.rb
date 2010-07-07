require File.dirname(__FILE__) + '/../test_helper'

class ContractTest < ActiveSupport::TestCase
  should_belong_to :account_executive
  should_belong_to :project
  should_have_many :deliverables

  should_validate_presence_of :name
  should_validate_presence_of :account_executive
  should_validate_presence_of :project
  should_validate_presence_of :start_date
  should_validate_presence_of :end_date

  should_not_allow_mass_assignment_of :project_id, :project, :discount_type
  
  should_allow_values_for :discount_type, "$", "%", nil, ''
  should_not_allow_values_for :discount_type, ["amount", "percent", "bar"]

  context "end_date" do
    should "be after start_date" do
      @contract = Contract.new(:start_date => Date.today, :end_date => Date.yesterday)

      assert @contract.invalid?
      assert_equal "must be greater than start date", @contract.errors.on(:end_date)
    end
  end

  should "QUESTION: name be unique"

  should "default executed to false" do
    @contract = Contract.new
    
    assert_equal false, @contract.executed
  end

  context "#labor_budget" do
    should "sum all of the labor budgets of the Deliverables" do
      contract = Contract.generate!
      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!
      LaborBudget.generate!(:deliverable => @deliverable_1, :budget => 100)
      contract.deliverables << @deliverable_2 = FixedDeliverable.generate!
      LaborBudget.generate!(:deliverable => @deliverable_2, :budget => 100)

      assert_equal 200, contract.labor_budget
    end
  end

  context "#overhead_budget" do
    should "sum all of the overhead budgets of the Deliverables" do
      contract = Contract.generate!
      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!
      OverheadBudget.generate!(:deliverable => @deliverable_1, :budget => 100)
      contract.deliverables << @deliverable_2 = FixedDeliverable.generate!
      OverheadBudget.generate!(:deliverable => @deliverable_2, :budget => 100)

      assert_equal 200, contract.overhead_budget
    end
  end

  context "#estimated_hour_budget" do
    should "sum all of the labor and overhead budgets of the Deliverables" do
      contract = Contract.generate!
      contract.deliverables << @deliverable_1 = FixedDeliverable.generate!
      LaborBudget.generate!(:deliverable => @deliverable_1, :hours => 50)
      contract.deliverables << @deliverable_2 = HourlyDeliverable.generate!
      OverheadBudget.generate!(:deliverable => @deliverable_2, :hours => 60)

      assert_equal 110, contract.estimated_hour_budget
    end
  end
end
