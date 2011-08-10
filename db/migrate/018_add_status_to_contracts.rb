class AddStatusToContracts < ActiveRecord::Migration
  def self.up
    add_column :contracts, :status, :string
    add_index :contracts, :status
  end

  def self.down
    remove_column :contracts, :status
  end
end
