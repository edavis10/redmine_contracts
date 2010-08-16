class AddFrequencyToDeliverables < ActiveRecord::Migration
  def self.up
    add_column :deliverables, :frequency, :string
  end

  def self.down
    remove_column :deliverables, :frequency
  end
end
