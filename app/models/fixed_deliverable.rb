class FixedDeliverable < Deliverable
  unloadable

  # Associations

  # Validations

  # Accessors

  def short_type
    'F'
  end

  def total
    read_attribute(:total) || 0.0
  end

  # Fixed deliverables are always 100% spent
  def total_spent
    total
  end

  # The amount of profit that is budgeted for this deliverable.
  # Profit = Total - ( Labor + Overhead + Fixed + Markup )
  def profit_budget
    budgets = labor_budget_total + overhead_budget_total
    (total || 0.0) - budgets
  end
  
  # Hardcoded value used as a wrapper for the old Budget plugin API.
  #
  # The Overhead plugin uses this in it's calcuations.
  def fixed_cost
    0
  end
end
