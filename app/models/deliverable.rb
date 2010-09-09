class Deliverable < ActiveRecord::Base
  unloadable

  ViewPrecision = 2
  
  # Associations
  belongs_to :contract
  belongs_to :manager, :class_name => 'User', :foreign_key => 'manager_id'
  has_many :labor_budgets
  has_many :overhead_budgets
  has_many :fixed_budgets
  has_many :issues

  accepts_nested_attributes_for :labor_budgets
  accepts_nested_attributes_for :overhead_budgets
  
  # Validations
  validates_presence_of :title
  validates_presence_of :type
  validates_presence_of :manager
  
  # Accessors

  delegate :name, :to => :contract, :prefix => true, :allow_nil => true

  # Callbacks

  # Register callbacks here, on new records the class isn't set so class-specific
  # callbacks don't fire.
  def after_save
    if type == "RetainerDeliverable"
      self.becomes(self.type.constantize).create_budgets_for_periods
    end
  end
  
  named_scope :by_title, {:order => "#{Deliverable.table_name}.title ASC"}
  
  def short_type
    ''
  end

  # Deliverable's aren't dated. Subclasses may override this for period behavior.
  def current_date
    nil
  end

  def to_s
    title
  end
  
  def to_underscore
    self.class.to_s.underscore
  end

  def total=(v)
    if v.is_a? String
      write_attribute(:total, v.gsub(/[$ ,]/, ''))
    else
      write_attribute(:total, v)
    end
  end

  def labor_budget_total(date=nil)
    labor_budgets.sum(:budget)
  end

  def overhead_budget_total(date=nil)
    overhead_budgets.sum(:budget)
  end

  def profit_budget(date=nil)
    nil
  end

  def labor_budget_hours(date=nil)
    labor_budgets.sum(:hours)
  end

  # Total number of hours estimated in the Deliverable's budgets
  def estimated_hour_budget_total
    (labor_budgets.sum(:hours) || 0.0) +
      (overhead_budgets.sum(:hours) || 0.0)
  end

  # OPTIMIZE: N+1
  def hours_spent_total
    issues.inject(0) {|total, issue| total += issue.spent_hours }
  end

  def filter_by_date(date=nil, &block)
    block.call
  end

  def retainer?
    type == "RetainerDeliverable"
  end

  def self.valid_types
    ['FixedDeliverable','HourlyDeliverable','RetainerDeliverable']
  end

  def self.valid_types_to_select
    valid_types.inject([]) do |types, type|
      types << [type.gsub(/Deliverable/i,''), type]
      types
    end
  end

  # Accessors from the budget plugin that need to be wrapped
  def subject
    warn "[DEPRECATION] Deliverable#subject is deprecated.  Please use Deliverable#title instead."
    title
  end

  def due
    warn "[DEPRECATION] Deliverable#due is deprecated.  Please use Deliverable#end_date instead."
    end_date
  end

  def hours_used
    warn "[DEPRECATION] Deliverable#hours_used is deprecated.  Please use Deliverable#hours_spent_total instead."
    hours_spent_total
  end

  def spent
    warn "[DEPRECATION] Deliverable#spent is deprecated.  Please use Deliverable#total_spent instead."
    total_spent
  end

  def total_hours
    warn "[DEPRECATION] Deliverable#total_hours is deprecated.  Please use Deliverable#estimated_hour_budget_total instead."
    estimated_hour_budget_total
  end

  def labor_budget
    warn "[DEPRECATION] Deliverable#labor_budget is deprecated.  Please use Deliverable#labor_budget_total instead."
    labor_budget_total
  end

  if Rails.env.test?
    generator_for :title, :method => :next_title

    def self.next_title
      @last_title ||= 'Deliverable 0000'
      @last_title.succ!
    end

  end
  
end
