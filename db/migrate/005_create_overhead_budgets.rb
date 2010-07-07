class CreateOverheadBudgets < ActiveRecord::Migration
  def self.up
    create_table :overhead_budgets do |t|
      t.decimal :hours, :precision => 15, :scale => 4
      t.decimal :budget, :precision => 15, :scale => 4
      t.references :deliverable
      t.timestamps
    end

    add_index :overhead_budgets, :deliverable_id
  end

  def self.down
    drop_table :overhead_budgets
  end
end
