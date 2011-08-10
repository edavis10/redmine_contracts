module ContractsHelper
  def setup_nested_deliverable_records(deliverable)
    deliverable.labor_budgets.build if deliverable.labor_budgets.empty?
    deliverable.overhead_budgets.build if deliverable.overhead_budgets.empty?
    deliverable.fixed_budgets.build if deliverable.fixed_budgets.empty?
    deliverable
  end

  def group_contracts_by_status(contracts)
    grouped_contracts = contracts.inject({}) do |grouped, contract|
      grouped[contract.status] ||= []
      grouped[contract.status] << contract
      grouped
    end
    grouped_contracts["open"] ||= []
    grouped_contracts["locked"] ||= []
    grouped_contracts["closed"] ||= []
    grouped_contracts
  end

  def deliverable_options(project)
    project.contracts.inject([]) do |data, contract|
      data << [contract.name, deliverable_options_for_contract(contract)]
    end
  end

  def grouped_deliverable_options_for_select(project, selected_key=nil)
    project.contracts.all(:include => :deliverables).inject([]) do |html, contract|
      if contract.closed? && !contract.deliverable_ids.include?(selected_key.to_i)
        # skip
      else
        options = contract.deliverables.collect do |deliverable|
          deliverable_option(deliverable, contract, selected_key)
        end

        html << content_tag(:optgroup, options.join("\n"), :label => h(contract.name))
      end
      html
    end.join('\n')
  end

  def deliverable_option(deliverable, contract, selected_key)
    option_attributes = {}
    option_attributes[:value] = h(deliverable.id)
    option_attributes[:selected] = "selected" if selected_key.to_i == deliverable.id
    option_attributes[:disabled] = "disabled" if (deliverable.locked? || contract.locked?) && selected_key.to_i != deliverable.id

    return "" if deliverable.closed? && option_attributes[:selected].blank? # Skip unselected, closed
      
    content_tag(:option, h(deliverable.title), option_attributes)
  end

  def deliverable_options_for_contract(contract)
    contract.deliverables.collect {|d| [d.title, d.id]}
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
    spent_value = object.send(spent_field)
    total_value = object.send(total_field)
    spent_content = send(formatter, spent_value)
    total_content = send(formatter, total_value)

    # Show overages except for profit fields
    overage_css_class = overage_class(spent_value, total_value) unless spent_field.to_s.match(/profit/i)
    
    show_field(object, spent_field, options.merge(:raw => true, :wrap_in_td => false)) do

      content_tag(:td, h(spent_content), :class => "spent #{overage_css_class}") +
        content_tag(:td, h(total_content), :class => 'budget')
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

  # Given a deliverable and period, validate the period
  # TODO: could use a better name
  def validate_period(deliverable, period)
    if deliverable.current_date && deliverable.within_period_range?(period)
      return period
    end
  end

  # Should the markup be display?
  # 
  # On Contracts and Deliverables, markup is hidden if both the spent
  # and budget is 0.
  def show_markup_for?(object, date=nil)
    if object.is_a?(Contract)
      !(object.fixed_markup_spent == 0 && object.fixed_markup_budget == 0)
    elsif object.is_a?(Deliverable)
      !(object.fixed_markup_budget_total_spent(date) == 0 && object.fixed_markup_budget_total(date) == 0)
    else
      true
    end
    
  end

  def link_to_issue_list_with_filter(text, options={})
    deliverable_id = options[:deliverable_id] || '*'
    status_id = options[:status_id] || '*'
    
    link_to(h(text), {
              :controller => 'issues',
              :action => 'index',
              :project_id => @project,
              :set_filter => 't',
              :status_id => status_id,
              :deliverable_id => deliverable_id
            })

  end

  def release(version=5, message='')
    return '' unless (1..5).include?(version)
    image_tag("todo#{version}.png", :plugin => 'redmine_contracts', :title => "Coming in release #{version}. #{message}")
  end

  # Overage occurs when spent is negative or spent is greater than budget
  def overage?(spent, budget, options={})
    return false unless spent && budget
    return true if spent < 0
    
    spent.to_f > budget.to_f
  end

  def overage_class(spent, budget, options={})
    if overage?(spent, budget, options)
      'overage'
    else
      ''
    end
  end
  
end
