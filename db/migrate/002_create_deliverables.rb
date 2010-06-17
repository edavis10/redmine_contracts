class CreateDeliverables < ActiveRecord::Migration
  def self.up
    create_table :deliverables do |t|
      t.string :title
      t.string :type
      t.date :start_date
      t.date :end_date
      t.notes :text
      t.boolean :feature_sign_off
      t.boolean :warranty_sign_off
      t.integer :manager_id # User
      t.references :contract
    end

    add_index :deliverables, :title
    add_index :deliverables, :type
    add_index :deliverables, :start_date
    add_index :deliverables, :end_date
    add_index :deliverables, :contract_id
  end

  def self.down
    drop_table :deliverables
  end
end
