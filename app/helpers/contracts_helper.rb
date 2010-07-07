module ContractsHelper
  def setup_nested_deliverable_records(deliverable)
    returning(deliverable) do |d|
      d.labor_budgets.build if d.labor_budgets.empty?
      d.overhead_budgets.build if d.overhead_budgets.empty?
    end
  end

  def format_budget_for_deliverable(deliverable, total)
    # TODO LATER: calculate amount used
    if total > 0
      content_tag(:span, "0", :class => 'spent-amount') +
        " " +
        content_tag(:span, h(number_to_currency(total, :unit => '')), :class => 'total-amount')
    else
      '---'
    end
  end
end
