module ContractsHelper
  def setup_nested_deliverable_records(deliverable)
    returning(deliverable) do |d|
      d.labor_budgets.build if d.labor_budgets.empty?
      d.overhead_budgets.build if d.overhead_budgets.empty?
    end
  end

  def format_budget_for_deliverable(deliverable, spent, total, options={})
    extra_css_class = options[:class] || ''
    
    if total > 0 || spent > 0
      content_tag(:td, h(format_value_field_for_contracts(spent)), :class => 'spent-amount ' + extra_css_class) +
        content_tag(:td, h(format_value_field_for_contracts(total)), :class => 'total-amount white ' + extra_css_class)
    else
      content_tag(:td, '----', :colspan => '2', :class => 'no-value ' + extra_css_class)
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
    label_html_options = options[:label_html_options] || {}
    label = content_tag(:strong, l(("field_" + field.to_s.gsub(/\_id$/, "")).to_sym) + ": ", :class => 'contract-details-label')

    formatter = options[:format]
    raw_content = options[:raw] || false
    wrap_in_td = options[:wrap_in_td]
    wrap_in_td = true if wrap_in_td.nil?

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

    if raw_content
      field_content = content
    else
      field_content = h(content)
    end
    
    content_tag(:tr,
                content_tag(:td, label, label_html_options) +
                (wrap_in_td ? content_tag(:td, field_content) : field_content),
                html_options)
  end

  def show_budget_field(object, spent_field, total_field, options={})

    formatter = options[:format] || :number_to_currency
    spent_content = send(formatter, object.send(spent_field))
    total_content = send(formatter, object.send(total_field))

    show_field(object, spent_field, options.merge(:raw => true, :wrap_in_td => false)) do

      content_tag(:td, h(spent_content), :class => 'spent') +
        content_tag(:td, h(total_content), :class => 'budget')
    end
  end

  def format_hourly_rate(decimal)
    number_to_currency(decimal, :precision => 0) + "/hr" if decimal
  end

  def format_payment_terms(value)
    return '' if value.blank?
    return h(value.name)
  end

  def format_deliverable_value_fields(value)
    number_with_precision(value, :precision => Deliverable::ViewPrecision, :delimiter => '')
  end

  def format_value_field_for_contracts(value)
    number_with_precision(value, :precision => Contract::ViewPrecision, :delimiter => ',')
  end

  def format_as_yes_or_no(value)
    if value
      l(:general_text_Yes)
    else
      l(:general_text_No)
    end
  end

  def retainer_period_options(deliverable, method_options={})
    selected = method_options[:selected]
    if selected && selected.is_a?(Date)
      selected = selected.strftime("%Y-%m")
    end

    options = []
    options << content_tag(:option, l(:label_all).capitalize, :value => '')

    deliverable.months.collect do |month|
      value = month.strftime("%Y-%m")
      options << content_tag(:option, month.strftime("%B %Y"), :value => value, :selected => (selected == value) ? 'selected' : nil)
    end
    
    options
  end
end
