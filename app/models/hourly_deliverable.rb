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
    hours = billable_hours_on_time_entries(time_logs)

    fixed_budget_amount = fixed_budget_total_spent(date) + fixed_markup_budget_total_spent(date)
    return (hours * contract.billable_rate) + fixed_budget_amount
  end
  
  # Block setting the total on HourlyDeliverables
  def total=(v)
    nil
  end

  def clear_total
    write_attribute(:total, nil)
  end

  protected

  def billable_hours_on_time_entries(time_entries)
    time_entries.inject(0) {|total, time_entry|
      total += time_entry.hours if time_entry.billable?
      total
    }
  end
end
