class HourlyDeliverable < Deliverable
  unloadable

  # Associations

  # Validations

  # Accessors

  # Callbacks
  before_save :clear_total

  def short_type
    'H'
  end

  def total
    return 0 if contract.nil?
    return 0 if contract.billable_rate.blank?
    return 0 if labor_budgets.count == 0 && overhead_budgets.count == 0

    hours = labor_budgets.sum(:hours) + overhead_budgets.sum(:hours)
    return contract.billable_rate * hours
  end
  
  # Block setting the total on HourlyDeliverables
  def total=(v)
    nil
  end

  def clear_total
    write_attribute(:total, nil)
  end

  # The amount of profit that is budgeted for this deliverable
  # Profit = Total - ( Labor + Overhead + Fixed + Markup )
  def profit_budget
    budgets = labor_budget_total + overhead_budget_total
    (total || 0.0) - budgets
  end
end
