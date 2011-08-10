class AddStatusToDeliverables < ActiveRecord::Migration
  def self.up
    add_column :deliverables, :status, :string
    add_index :deliverables, :status
  end

  def self.down
    remove_column :deliverables, :status
  end
end
