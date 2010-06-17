class Contract < ActiveRecord::Base
  unloadable

  # Associations
  belongs_to :project
  belongs_to :account_executive, :class_name => 'User', :foreign_key => 'account_executive_id'
  
end
