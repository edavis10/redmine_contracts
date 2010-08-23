class AddYearAndMonthToLaborBudgets < ActiveRecord::Migration
  def self.up
    add_column :labor_budgets, :year, :integer
    add_index :labor_budgets, :year

    add_column :labor_budgets, :month, :integer
    add_index :labor_budgets, :month
  end

  def self.down
    remove_column :labor_budgets, :year
    remove_column :labor_budgets, :month
  end
end
