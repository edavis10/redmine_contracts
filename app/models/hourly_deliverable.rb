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

  # Total = ( Labor Hours * Billing Rate ) + ( Fixed + Markup )
  def total(date=nil)
    return 0 if contract.nil?
    return 0 if contract.billable_rate.blank?
    return 0 if labor_budgets.count == 0 && overhead_budgets.count == 0

    fixed_budget_amount = fixed_budget_total(date) + fixed_markup_budget_total(date)
    return (contract.billable_rate * labor_budget_hours(date)) + fixed_budget_amount
  end

  # Total amount to be billed on the deliverable, using the total time logged
  # and the contract rate
  def total_spent(date=nil)
    return 0 if contract.nil?
    return 0 if contract.billable_rate.blank?
    return 0 unless self.issues.count > 0

    time_logs = self.issues.collect(&:time_entries).flatten
    hours = time_logs.inject(0) {|total, time_entry|
      total += time_entry.hours if time_entry.billable?
      total
    }

    return hours * contract.billable_rate
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
  def profit_budget(date=nil)
    budgets = labor_budget_total(date) + overhead_budget_total(date) + fixed_budget_total(date) + fixed_markup_budget_total(date)
    (total(date) || 0.0) - budgets
  end

  # The amount of money remaining after expenses have been taken out
  # Profit left = Total - Labor spent - Overhead spent
  def profit_left(date=nil)
    total_spent(date) - labor_budget_spent(date) - overhead_spent(date)
  end
end
