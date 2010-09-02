# A RetainerDeliverable is an HourlyDeliverable that is renewed at
# regular calendar periods.  The Company bills a regular number of
# hours for a hourly rate whereby the budgets are reset over a
# regular cyclical period (monthly).
class RetainerDeliverable < HourlyDeliverable
  unloadable

  # Associations

  # Validations
  
  # Accessors

  # Callbacks
  before_update :check_for_extended_period
  before_update :check_for_shrunk_period
  
  def short_type
    'R'
  end

  def current_period
    'TODO'
  end

  def beginning_date
    start_date && start_date.beginning_of_month.to_date
  end

  def ending_date
    end_date && end_date.end_of_month.to_date
  end

  def months
    month_acc = []

    current_date = beginning_date
    return [] if current_date.nil? || ending_date.nil?
    
    while current_date < ending_date do
      month_acc << current_date
      current_date = current_date.advance(:months => 1)
    end
    
    month_acc
  end

  # Returns the months used by the Deliverable that are before date
  def months_before_date(date)
    months.select {|m| m < date }
  end

  # Returns the months used by the Deliverable that are after date
  def months_after_date(date)
    months.select {|m| m > date }
  end

  def labor_budgets_for_date(date)
    budgets = labor_budgets.all(:conditions => {:year => date.year, :month => date.month})
    budgets = [labor_budgets.build(:year => date.year, :month => date.month)] if budgets.empty?
    budgets
  end

  def overhead_budgets_for_date(date)
    budgets = overhead_budgets.all(:conditions => {:year => date.year, :month => date.month})
    budgets = [overhead_budgets.build(:year => date.year, :month => date.month)] if budgets.empty?
    budgets
  end

  def create_budgets_for_periods
    # For each month in the time span
    months.each do |month|
      # Iterate over all un-dated budgets, created dated versions
      undated_labor_budgets = labor_budgets.all(:conditions => ["#{LaborBudget.table_name}.year IS NULL AND #{LaborBudget.table_name}.month IS NULL"])
      undated_labor_budgets.each do |template_budget|
        labor_budgets.create(template_budget.attributes.merge(:year => month.year, :month => month.month))
      end

      undated_overhead_budgets = overhead_budgets.all(:conditions => ["#{OverheadBudget.table_name}.year IS NULL AND #{OverheadBudget.table_name}.month IS NULL"])
      undated_overhead_budgets.each do |template_budget|
        overhead_budgets.create(template_budget.attributes.merge(:year => month.year, :month => month.month))
      end
    end
    # Destroy origional un-dated budgets
    labor_budgets.all(:conditions => ["#{LaborBudget.table_name}.year IS NULL AND #{LaborBudget.table_name}.month IS NULL"]).collect(&:destroy)
    overhead_budgets.all(:conditions => ["#{OverheadBudget.table_name}.year IS NULL AND #{OverheadBudget.table_name}.month IS NULL"]).collect(&:destroy)
  end

  def check_for_extended_period
    # TODO: brute force. Alternative would be to check end_date_changes to see if the period actually shifted
    if end_date_changed?
      extend_period_to_new_end_date
    end

    # TODO: brute force. Alternative would be to check start_date_changes to see if the period actually shifted
    if start_date_changed?
      extend_period_to_new_start_date
    end
  end

  def check_for_shrunk_period
    if end_date_changed? || start_date_changed?
      shrink_budgets_to_new_period
    end
  end

  private

  def shrink_budgets_to_new_period
    return if beginning_date.nil? || ending_date.nil?
    labor_budgets.all.each do |labor_budget|
      # Purge un-dated budgets, should not be saved at all
      labor_budget.destroy unless labor_budget.year.present?
      labor_budget.destroy unless labor_budget.month.present?

      # Purge budgets outside the new beginning/ending range
      unless (beginning_date..ending_date).to_a.include?(Date.new(labor_budget.year, labor_budget.month, 1))
        labor_budget.destroy
      end
    end

    overhead_budgets.all.each do |overhead_budget|
      # Purge un-dated budgets, should not be saved at all
      overhead_budget.destroy unless overhead_budget.year.present?
      overhead_budget.destroy unless overhead_budget.month.present?

      # Purge budgets outside the new beginning/ending range
      unless (beginning_date..ending_date).to_a.include?(Date.new(overhead_budget.year, overhead_budget.month, 1))
        overhead_budget.destroy
      end
    end

    true
  end

  def extend_period_to_new_end_date
    return if end_date_change[0].nil? # No previous end date, so it will not have budgets

    old_end_date = end_date_change[0]
    last_labor_budgets = labor_budgets.all(:conditions => {:year => old_end_date.year, :month => old_end_date.month})
    last_overhead_budgets = overhead_budgets.all(:conditions => {:year => old_end_date.year, :month => old_end_date.month})

    months_after_date(old_end_date.end_of_month.to_date).each do |new_period|
      create_budgets_for_new_period(new_period, last_labor_budgets, last_overhead_budgets)
    end
  end

  def extend_period_to_new_start_date
    return if start_date_change[0].nil? # No previous start date, so it will not have budgets
    
    old_start_date = start_date_change[0]
    first_labor_budgets = labor_budgets.all(:conditions => {:year => old_start_date.year, :month => old_start_date.month})
    first_overhead_budgets = overhead_budgets.all(:conditions => {:year => old_start_date.year, :month => old_start_date.month})
    
    months_before_date(old_start_date.beginning_of_month.to_date).each do |new_period|
      create_budgets_for_new_period(new_period, first_labor_budgets, first_overhead_budgets)
    end

  end

  def create_budgets_for_new_period(new_period, labor_budgets_to_copy, overhead_budgets_to_copy)
    labor_budgets_to_copy.each do |labor_budget_to_copy|
      create_new_labor_budget_based_on_existing_budget(labor_budget_to_copy, 'year' => new_period.year, 'month' => new_period.month)
    end

    overhead_budgets_to_copy.each do |overhead_budget_to_copy|
      create_new_overhead_budget_based_on_existing_budget(overhead_budget_to_copy, 'year' => new_period.year, 'month' => new_period.month)
    end
  end
  
  def create_new_labor_budget_based_on_existing_budget(existing_labor_budget, attributes={})
    labor_budgets.create(existing_labor_budget.attributes.except('id').merge(attributes))
  end

  def create_new_overhead_budget_based_on_existing_budget(existing_overhead_budget, attributes={})
    overhead_budgets.create(existing_overhead_budget.attributes.except('id').merge(attributes))
  end
end
