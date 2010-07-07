module ContractsHelper
  def setup_nested_deliverable_records(deliverable)
    returning(deliverable) do |d|
      d.labor_budgets.build if d.labor_budgets.empty?
      d.overhead_budgets.build if d.overhead_budgets.empty?
    end
  end

  def format_budget_for_deliverable(deliverable, spent, total)
    if total > 0 || spent > 0
      content_tag(:div, h(number_to_currency(spent, :unit => '')), :class => 'spent-amount') +
        content_tag(:div, h(number_to_currency(total, :unit => '')), :class => 'total-amount')
    else
      '---'
    end
  end
end
