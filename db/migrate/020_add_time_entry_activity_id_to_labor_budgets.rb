class AddTimeEntryActivityIdToLaborBudgets < ActiveRecord::Migration
  def self.up
    add_column :labor_budgets, :time_entry_activity_id, :integer
    add_index :labor_budgets, :time_entry_activity_id
  end

  def self.down
    remove_column :labor_budgets, :time_entry_activity_id
  end
end
