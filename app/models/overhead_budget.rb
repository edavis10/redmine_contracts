class OverheadBudget < ActiveRecord::Base
  unloadable

  # Associations
  belongs_to :deliverable
  belongs_to :time_entry_activity

  # Validations
  validates_presence_of :time_entry_activity_id

  # Accessors
  include DollarizedAttribute
  dollarized_attribute :budget
end
