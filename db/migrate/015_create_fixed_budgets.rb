class CreateFixedBudgets < ActiveRecord::Migration
  def self.up
    create_table :fixed_budgets do |t|
      t.string :title
      t.decimal :budget, :precision => 15, :scale => 4
      t.string :markup
      t.text :description
      t.references :deliverable
      
      t.timestamps
    end

    add_index :fixed_budgets, :deliverable_id
  end

  def self.down
    drop_table :fixed_budgets
  end
end
