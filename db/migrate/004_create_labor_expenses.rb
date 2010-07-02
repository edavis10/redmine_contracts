class CreateLaborExpenses < ActiveRecord::Migration
  def self.up
    create_table :labor_expenses do |t|
      t.decimal :hours, :precision => 15, :scale => 4
      t.decimal :budget, :precision => 15, :scale => 4
      t.references :deliverable
      t.timestamps
    end

    add_index :labor_expenses, :deliverable_id
  end

  def self.down
    drop_table :labor_expenses
  end
end
