class Deliverable < ActiveRecord::Base
  unloadable

  # Associations
  belongs_to :contract
  belongs_to :manager, :class_name => 'User', :foreign_key => 'manager_id'

  # Validations

  # Accessors

  def short_type
    ''
  end
end
