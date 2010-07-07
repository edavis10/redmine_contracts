class AddDeliverableIdToIssues < ActiveRecord::Migration
  def self.up
    # Skip adding the column if it exists from the Budget plugin
    unless Issue.column_names.include?('deliverable_id')
      add_column :issues, :deliverable_id, :integer
    end
  end
  
  def self.down
    remove_column :issues, :deliverable_id
  end
end
