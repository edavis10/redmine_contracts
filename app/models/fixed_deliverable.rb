class FixedDeliverable < Deliverable
  unloadable

  # Associations

  # Validations

  # Accessors

  def short_type
    'F'
  end

  def total(date=nil)
    read_attribute(:total) || 0.0
  end

  # Fixed deliverables are always 100% spent
  def total_spent(date=nil)
    total
  end

  # Hardcoded value used as a wrapper for the old Budget plugin API.
  #
  # The Overhead plugin uses this in it's calcuations.
  def fixed_cost
    0
  end
end
