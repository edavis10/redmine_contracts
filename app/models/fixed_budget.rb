class FixedBudget < ActiveRecord::Base
  unloadable

  # Associations
  belongs_to :deliverable

  # Validations

  # Accessors
  def budget=(v)
    if v.is_a? String
      write_attribute(:budget, v.gsub(/[$ ,]/, ''))
    else
      write_attribute(:budget, v)
    end
  end

  named_scope :by_period, lambda {|date|
    if date
      {
        :conditions => {:year => date.year, :month => date.month}
      }
    end
  }

  named_scope :paid, {:conditions => {:paid => true}}

  def markup_value
    return 0 if budget.blank? || markup.blank?

    case
    when percent_markup?
      percent = markup.gsub('%','').to_f
      return budget.to_f * (percent / 100)
    when straight_markup?
      markup.gsub('$','').gsub(',','').to_f
    else
      0 # Invalid markup
    end
    
  end

  def budget_spent
    if paid?
      budget
    else
      0
    end
  end

  def percent_markup?
    markup && markup.match(/%/)
  end

  def straight_markup?
    markup && markup.match(/\$/)
  end

  # Is this a blank budget item. Retainers will create blank ones when
  # they are copied. (RetainerDeliverable#create_budgets_for_periods)
  def blank_record?
    return true if new_record?
    return title.blank? && budget.blank? && markup.blank?
  end
end
