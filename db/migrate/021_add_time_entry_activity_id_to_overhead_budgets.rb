class AddTimeEntryActivityIdToOverheadBudgets < ActiveRecord::Migration
  def self.up
    add_column :overhead_budgets, :time_entry_activity_id, :integer
    add_index :overhead_budgets, :time_entry_activity_id
  end

  def self.down
    remove_column :overhead_budgets, :time_entry_activity_id
  end
end
