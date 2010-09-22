class AddYearAndMonthToFixedBudgets < ActiveRecord::Migration
  def self.up
    add_column :fixed_budgets, :year, :integer
    add_index :fixed_budgets, :year

    add_column :fixed_budgets, :month, :integer
    add_index :fixed_budgets, :month
  end

  def self.down
    remove_column :fixed_budgets, :year
    remove_column :fixed_budgets, :month
  end
end
