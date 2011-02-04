class Deliverable < ActiveRecord::Base
  unloadable

  ViewPrecision = 2
  
  # Associations
  belongs_to :contract
  belongs_to :manager, :class_name => 'User', :foreign_key => 'manager_id'
  has_many :labor_budgets
  has_many :overhead_budgets
  has_many :fixed_budgets
  has_many :issues, :dependent => :nullify

  accepts_nested_attributes_for :labor_budgets
  accepts_nested_attributes_for :overhead_budgets
  accepts_nested_attributes_for :fixed_budgets
  
  # Validations
  validates_presence_of :title
  validates_presence_of :type
  validates_presence_of :manager
  
  # Accessors
  include DollarizedAttribute
  dollarized_attribute :total

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

  def humanize_type
    type.to_s.sub('Deliverable','')
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

  def labor_budget_total(date=nil)
    memoize_by_date("@labor_budget_total", date) do
      labor_budgets.sum(:budget)
    end
  end

  def overhead_budget_total(date=nil)
    memoize_by_date("@overhead_budget_total", date) do
      overhead_budgets.sum(:budget)
    end
  end

  # The amount of profit that is budgeted for this deliverable.
  # Profit = Total - ( Labor + Overhead + Fixed + Markup )
  def profit_budget(date=nil)
    memoize_by_date("@profit_budget", date) do
      budgets = labor_budget_total(date) + overhead_budget_total(date) + fixed_budget_total(date) + fixed_markup_budget_total(date)
      (total(date) || 0.0) - budgets
    end
  end

  # The amount of money remaining after expenses have been taken out
  # Profit left = Total - Labor spent - Overhead spent - Fixed - Markup
  def profit_left(date=nil)
    memoize_by_date("@profit_left", date) do
      total_spent(date) - labor_budget_spent(date) - overhead_spent(date) - fixed_budget_total_spent(date) - fixed_markup_budget_total_spent(date)
    end
  end
  
  def labor_budget_hours(date=nil)
    memoize_by_date("@labor_budget_hours", date) do
      labor_budgets.sum(:hours)
    end
  end

  def overhead_budget_hours(date=nil)
    memoize_by_date("@overhead_budget_hours", date) do
      overhead_budgets.sum(:hours)
    end
  end

  # Total number of hours estimated in the Deliverable's budgets
  def estimated_hour_budget_total(date=nil)
    memoize_by_date("@estimated_hour_budget_total", date) do
      labor_budget_hours(date) + overhead_budget_hours(date)
    end
  end

  # OPTIMIZE: N+1
  def labor_hours_spent_total(date=nil)
    memoize_by_date("@labor_hours_spent_total", date) do
      issues.inject(0) {|total, issue| total += issue.billable_time_spent } # From redmine_overhead
    end
  end

  # OPTIMIZE: N+1
  def overhead_hours_spent_total(date=nil)
    memoize_by_date("@overhead_hours_spent_total", date) do
      issues.inject(0) {|total, issue| total += issue.overhead_time_spent } # From redmine_overhead
    end
  end

  def hours_spent_total(date=nil)
    return 0 if issues.empty?

    # Don't count subissues
    TimeEntry.sum(:hours, :conditions => { :issue_id => issues.collect(&:id) })
  end

  def fixed_budget_total(date=nil)
    memoize_by_date("@fixed_budget_total", date) do
      fixed_budgets.sum(:budget)
    end
  end

  def fixed_budget_total_spent(date=nil)
    memoize_by_date("@fixed_budget_total_spent", date) do
      fixed_budgets.paid.sum(:budget)
    end
  end

  # OPTIMIZE: N+1
  def fixed_markup_budget_total(date=nil)
    memoize_by_date("@fixed_markup_budget_total", date) do
      fixed_budgets.inject(0) {|total, fixed_budget| total += fixed_budget.markup_value }
    end
  end
  
  # OPTIMIZE: N+1
  def fixed_markup_budget_total_spent(date=nil)
    memoize_by_date("@fixed_markup_budget_total_spent", date) do
      fixed_budgets.paid.inject(0) {|total, fixed_budget| total += fixed_budget.markup_value }
    end
  end
  
  def filter_by_date(date=nil, &block)
    block.call
  end

  def issues_by_status
    issues.inject({}) {|grouped, issue|
      grouped[issue.status] ||= []
      grouped[issue.status] << issue
      grouped
    }
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

  private

  def memoize_by_date(ivar, date, &block)
    cache_hash  = instance_variable_get(ivar)
    cache_hash ||= {}

    if date
      if date.is_a?(Date)
        cache_key = "#{date.year}-#{date.month}"
      else
        cache_key = :invalid
      end
    else
      cache_key = :all
    end

    cache_hash[cache_key] ||= block.call
    instance_variable_set(ivar, cache_hash)
    
    cache_hash[cache_key]
  end
end
