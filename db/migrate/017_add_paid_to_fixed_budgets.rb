class AddPaidToFixedBudgets < ActiveRecord::Migration
  def self.up
    add_column :fixed_budgets, :paid, :boolean
    add_index :fixed_budgets, :paid
  end

  def self.down
    remove_column :fixed_budgets, :paid
  end
end
