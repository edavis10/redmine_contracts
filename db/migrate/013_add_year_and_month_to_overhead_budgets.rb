class AddYearAndMonthToOverheadBudgets < ActiveRecord::Migration
  def self.up
    add_column :overhead_budgets, :year, :integer
    add_index :overhead_budgets, :year

    add_column :overhead_budgets, :month, :integer
    add_index :overhead_budgets, :month
  end

  def self.down
    remove_column :overhead_budgets, :year
    remove_column :overhead_budgets, :month
  end
end
