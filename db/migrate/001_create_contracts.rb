class CreateContracts < ActiveRecord::Migration
  def self.up
    create_table :contracts do |t|
      t.string :name
      t.integer :account_executive_id # User
      t.references :project
      t.date :start_date
      t.date :end_date
      t.boolean :executed
      t.decimal :billable_rate, :precision => 15, :scale => 2
      t.string :discount
      t.string :discount_type # $ or %
      t.text :discount_note
      t.string :payment_terms
      t.text :client_ap_contact_information
      t.string :po_number
      t.text :details
      t.timestamps
    end

    add_index :contracts, :name
    add_index :contracts, :account_executive_id
    add_index :contracts, :project_id
    add_index :contracts, :start_date
    add_index :contracts, :end_date
  end

  def self.down
    drop_table :contracts
  end
end
