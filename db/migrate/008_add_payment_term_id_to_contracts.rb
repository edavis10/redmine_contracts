class AddPaymentTermIdToContracts < ActiveRecord::Migration
  def self.up
    add_column :contracts, :payment_term_id, :integer
  end

  def self.down
    remove_column :contracts, :payment_term_id
  end
end
