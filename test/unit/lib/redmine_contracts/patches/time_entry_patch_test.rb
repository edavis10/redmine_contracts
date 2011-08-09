require File.dirname(__FILE__) + '/../../../../test_helper'

class RedmineContracts::Patches::TimeEntryTest < ActionController::TestCase

  def setup
    @project = Project.generate!
    @contract = Contract.generate!(:project => @project, :status => 'open')
    @deliverable = FixedDeliverable.generate!(:contract => @contract, :status => 'open').reload
    @issue = Issue.generate_for_project!(@project, :deliverable => @deliverable).reload
    assert_equal @deliverable, @issue.deliverable
    @user = User.generate!
    @role = Role.generate!
    User.add_to_project(@user, @project, @role)
    @activity = TimeEntryActivity.generate!
  end

  def create_time_entry
    @issue.reload
    @time_entry = TimeEntry.create(:issue => @issue,
                                   :project => @project,
                                   :spent_on => Date.today,
                                   :activity => @activity,
                                   :hours => 10,
                                   :user => @user)
  end

  def assert_error_about_locked_deliverable(time_entry)
    assert_equal "Can't create a time entry on a locked deliverable", time_entry.errors.on_base
  end

  def assert_error_about_locked_contract(time_entry)
    assert_equal "Can't create a time entry on a locked contract", time_entry.errors.on_base
  end

  def assert_error_about_closed_deliverable(time_entry)
    assert_equal "Can't create a time entry on a closed deliverable", time_entry.errors.on_base
  end

  def assert_error_about_closed_contract(time_entry)
    assert_equal "Can't create a time entry on a closed contract", time_entry.errors.on_base
  end

  should "allow logging time to an issue on an open deliverable, open contract" do
    assert_difference("TimeEntry.count") { create_time_entry }
  end

  should "block logging time to an issue on a locked deliverable, open contract" do
    assert @deliverable.lock!
    assert @deliverable.locked?
    
    assert_no_difference("TimeEntry.count") { create_time_entry }
    assert_error_about_locked_deliverable(@time_entry)
  end

  should "block logging time to an issue on an open deliverable, locked contract" do
    assert @contract.lock!
    assert @contract.locked?

    assert_no_difference("TimeEntry.count") { create_time_entry }
    assert_error_about_locked_contract(@time_entry)
  end
  
  should "block logging time to an issue on a locked deliverable, locked contract" do
    assert @deliverable.lock!
    assert @deliverable.locked?
    assert @contract.lock!
    assert @contract.locked?

    assert_no_difference("TimeEntry.count") { create_time_entry }
    assert @time_entry.errors.on_base.include?("Can't create a time entry on a locked deliverable")
    assert @time_entry.errors.on_base.include?("Can't create a time entry on a locked contract")
  end

  should "block logging time to an issue on a closed deliverable, open contract" do
    assert @deliverable.close!
    assert @deliverable.closed?
    
    assert_no_difference("TimeEntry.count") { create_time_entry }
    assert_error_about_closed_deliverable(@time_entry)
  end

  should "block logging time to an issue on a closed deliverable, locked contract" do
    assert @deliverable.close!
    assert @deliverable.closed?
    assert @contract.lock!
    assert @contract.locked?
    
    assert_no_difference("TimeEntry.count") { create_time_entry }
    assert @time_entry.errors.on_base.include?("Can't create a time entry on a closed deliverable")
    assert @time_entry.errors.on_base.include?("Can't create a time entry on a locked contract")
  end

  should "block logging time to an issue on an open deliverable, closed contract" do
    assert @contract.close!
    assert @contract.closed?
    
    assert_no_difference("TimeEntry.count") { create_time_entry }
    assert_error_about_closed_contract(@time_entry)
  end

  should "block logging time to an issue on a locked deliverable, closed contract" do
    assert @deliverable.lock!
    assert @deliverable.locked?
    assert @contract.close!
    assert @contract.closed?
    
    assert_no_difference("TimeEntry.count") { create_time_entry }
    assert @time_entry.errors.on_base.include?("Can't create a time entry on a locked deliverable")
    assert @time_entry.errors.on_base.include?("Can't create a time entry on a closed contract")
  end
  
  should "block logging time to an issue on a closed deliverable, closed contract" do
    assert @deliverable.close!
    assert @deliverable.closed?
    assert @contract.close!
    assert @contract.closed?
    
    assert_no_difference("TimeEntry.count") { create_time_entry }
    assert @time_entry.errors.on_base.include?("Can't create a time entry on a closed deliverable")
    assert @time_entry.errors.on_base.include?("Can't create a time entry on a closed contract")
  end
  
end
