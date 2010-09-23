class OverheadBudget < ActiveRecord::Base
  unloadable

  # Associations
  belongs_to :deliverable

  # Validations

  # Accessors
  include DollarizedAttribute
  dollarized_attribute :budget
end
