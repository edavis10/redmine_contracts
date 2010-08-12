class RemovePaymentTermsFromContracts < ActiveRecord::Migration
  def self.up
    remove_column :contracts, :payment_terms
  end

  def self.down
    add_column :contracts, :payment_terms, :string
  end
end
