class AddTotalToDeliverables < ActiveRecord::Migration
  def self.up
    add_column :deliverables, :total, :decimal, :precision => 15, :scale => 2

    add_index :deliverables, :total
  end

  def self.down
    remove_column :deliverables, :total
  end
end
