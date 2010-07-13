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
  def show_field(object, field, options={}, &block)
    html_options = options[:html_options] || {}
    label = content_tag(:span, l(("field_" + field.to_s.gsub(/\_id$/, "")).to_sym) + ": ", :class => 'contract-details-label')

    formatter = options[:format]
    raw_content = options[:raw] || false

    content = ''
    
    if block_given?
      content = yield
    else
      content = if formatter
                  send(formatter, object.send(field))
                else
                  object.send(field)
                end
    end
    
    content_tag(:p,
                label +
                (raw_content ? content : h(content)),
                html_options)
  end

  def show_budget_field(object, spent_field, total_field, options={})

    formatter = options[:format] || :number_to_currency
    spent_content = send(formatter, object.send(spent_field))
    total_content = send(formatter, object.send(total_field))

    show_field(object, spent_field, options.merge(:raw => true)) do

      content_tag(:span, h(spent_content), :class => 'spent') +
        content_tag(:span, h(total_content), :class => 'budget')
    end
  end

  def format_hourly_rate(decimal)
    number_to_currency(decimal) + "/hr" if decimal
  end

  def format_payment_terms(value)
    return '' if value.blank?
    return l(Contract::PaymentTerms[value.to_sym])
  end
end
