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

  # The amount of profit that is budgeted for this deliverable.
  # Profit = Total - ( Labor + Overhead + Fixed + Markup )
  def profit_budget(date=nil)
    budgets = labor_budget_total(date) + overhead_budget_total(date) + fixed_budget_total(date) + fixed_markup_budget_total(date)
    (total(date) || 0.0) - budgets
  end

  # The amount of money remaining after expenses have been taken out
  # Profit left = Total - Labor spent - Overhead spent
  def profit_left(date=nil)
    total_spent(date) - labor_budget_spent(date) - overhead_spent(date)
  end
  
  # Hardcoded value used as a wrapper for the old Budget plugin API.
  #
  # The Overhead plugin uses this in it's calcuations.
  def fixed_cost
    0
  end
end
