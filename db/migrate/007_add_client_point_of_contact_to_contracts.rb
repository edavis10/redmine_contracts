class AddClientPointOfContactToContracts < ActiveRecord::Migration
  def self.up
    add_column :contracts, :client_point_of_contact, :text
  end

  def self.down
    remove_column :contracts, :client_point_of_contact
  end
end
