class RemoveFrequencyFromDeliverables < ActiveRecord::Migration
  def self.up
    remove_column :deliverables, :frequency
  end

  def self.down
    add_column :deliverables, :frequency, :string
  end
end
