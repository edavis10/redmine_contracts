# Formatting helpers
module ContractFormatterHelper
  def format_as_yes_or_no(value)
    if value
      l(:general_text_Yes)
    else
      l(:general_text_No)
    end
  end

  def format_budget_for_deliverable(deliverable, spent, total, options={})
    extra_css_class = options[:class] || ''

    if total > 0 || spent > 0
      spent_css_classes = 'spent-amount'
      spent_css_classes << " #{overage_class(spent, total)}"
      spent_css_classes << ' ' << extra_css_class
      total_css_classes = 'total-amount white'
      total_css_classes << ' ' << extra_css_class
      
      content_tag(:td, h(format_value_field_for_contracts(spent)), :class => spent_css_classes) +
        content_tag(:td, h(format_value_field_for_contracts(total)), :class => total_css_classes)
    else
      content_tag(:td, '----', :colspan => '2', :class => 'no-value ' + extra_css_class)
    end
  end

  def format_deliverable_value_fields(value)
    number_with_precision(value, :precision => Deliverable::ViewPrecision, :delimiter => '')
  end

  def format_deliverable_value_fields_as_dollar_or_percent(value)
    if value.to_s.match('%')
      h(value)
    else # currency or straight amount
      number_to_currency(value.to_s.gsub('$',''), :precision => Deliverable::ViewPrecision, :delimiter => '', :unit => '$')
    end
  end

  def format_hourly_rate(decimal)
    number_to_currency(decimal, :precision => 0) + "/hr" if decimal
  end

  def format_payment_terms(value)
    return '' if value.blank?
    return h(value.name)
  end

  def format_value_field_for_contracts(value, options={})
    opt = {:unit => '', :precision => Contract::ViewPrecision, :delimiter => ','}.merge(options)
    number_to_currency(value, opt)
  end

end
