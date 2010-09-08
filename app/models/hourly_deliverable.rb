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

  def total(date=nil)
    return 0 if contract.nil?
    return 0 if contract.billable_rate.blank?
    return 0 if labor_budgets.count == 0 && overhead_budgets.count == 0

    return contract.billable_rate * labor_budget_hours(date)
  end

  # Total amount to be billed on the deliverable, using the total time logged
  # and the contract rate
  def total_spent
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
    budgets = labor_budget_total(date) + overhead_budget_total(date)
    (total(date) || 0.0) - budgets
  end

  # The amount of money remaining after expenses have been taken out
  # Profit left = Total - Labor spent - Overhead spent
  def profit_left
    total_spent - labor_budget_spent - overhead_spent
  end
end
