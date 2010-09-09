class FixedBudget < ActiveRecord::Base
  unloadable

  # Associations
  belongs_to :deliverable

  # Validations

  # Accessors
end
