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

  # Simple helper to show the values of a field on an object in a standard format
  #
  # <p>
  #  <span>Label: </span>
  #  Field value
  # </p>
  def show_field(object, field, options={})
    html_options = options[:html_options] || {}
    label = content_tag(:span, l(("field_" + field.to_s.gsub(/\_id$/, "")).to_sym) + ": ")

    formatter = options[:format]

    content = if formatter
                send(formatter, object.send(field))
              else
                object.send(field)
              end
    
    content_tag(:p,
                label +
                h(content),
                html_options)
  end

  def format_hourly_rate(decimal)
    number_to_currency(decimal) + "/hr" if decimal
  end
end
