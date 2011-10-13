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

  accepts_nested_attributes_for :labor_budgets, :allow_destroy => true
  accepts_nested_attributes_for :overhead_budgets, :allow_destroy => true
  accepts_nested_attributes_for :fixed_budgets, :allow_destroy => true
  
  # Validations
  validates_presence_of :title
  validates_presence_of :type
  validates_presence_of :manager
  validates_inclusion_of :status, :in => ["open","locked","closed"], :allow_blank => true, :allow_nil => true
  validate_on_update :validate_status_changes
  validate :validate_contract_status
  
  # Accessors
  include DollarizedAttribute
  dollarized_attribute :total

  delegate :name, :to => :contract, :prefix => true, :allow_nil => true
  delegate "open?", :to => :contract, :prefix => true, :allow_nil => true
  delegate "closed?", :to => :contract, :prefix => true, :allow_nil => true
  delegate "locked?", :to => :contract, :prefix => true, :allow_nil => true
  delegate :project, :to => :contract, :allow_nil => true
  
  # Callbacks
  before_destroy :block_on_locked_contracts
  before_destroy :block_on_closed_contracts
  
  def after_initialize
    self.status = "open" unless self.status.present?
  end
  
  # Register callbacks here, on new records the class isn't set so class-specific
  # callbacks don't fire.
  def after_save
    if type == "RetainerDeliverable"
      self.becomes(self.type.constantize).create_budgets_for_periods
    end
  end
  
  named_scope :by_title, {:order => "#{Deliverable.table_name}.title ASC"}
  named_scope :with_status, lambda {|statuses|
    {
      :conditions => ["#{Deliverable.table_name}.status IN (?)", statuses]
    }
  }
  
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

  def lock!
    update_attribute(:status, "locked")
  end

  def close!
    update_attribute(:status, "closed")
  end

  def open?
    self.status == "open"
  end

  def locked?
    self.status == "locked"
  end

  def closed?
    self.status == "closed"
  end

  def editable?
    (new_record? || open?)
  end

  def valid_status_change?
    change_to_status_only? || changing_to_the_open_status? || changing_from_the_open_status?
  end

  def change_to_status_only?
    ["status"] == changes.keys
  end

  def changing_to_the_open_status?
    changes["status"].present? && "open" == changes["status"].second
  end

  def changing_from_the_open_status?
    changes["status"].present? && "open" == changes["status"].first
  end

  # TODO: duplicated on Contract, refactor after one more duplication
  def validate_status_changes
    return if valid_status_change?

    errors.add_to_base(:cant_update_locked_deliverable) if locked?
    errors.add_to_base(:cant_update_closed_deliverable) if closed?
  end

  def validate_contract_status
    return if contract_open?
    return if change_to_status_only?

    if contract_locked?
      if new_record?
        errors.add_to_base(:cant_create_deliverable_on_locked_contract)
      else
        errors.add_to_base(:cant_update_locked_contract)
      end
    end

    if contract_closed?
      if new_record?
        errors.add_to_base(:cant_create_deliverable_on_closed_contract)
      else
        errors.add_to_base(:cant_update_closed_contract)
      end
    end
  end

  # No operation method, useful to clean up logic with an optional message
  # for documentation
  def noop(message="")
  end

  def block_on_locked_contracts
    !contract_locked?
  end

  def block_on_closed_contracts
    !contract_closed?
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

  def billable_time_entry_activities
    project.activities.select {|activity| activity.billable? }
  end

  def non_billable_time_entry_activities
    project.activities.reject {|activity| activity.billable? }
  end

  # Total amount spent ($) for a given activity
  def spent_for_activity(activity)
    issues.all.inject(0.0) do |all_issues_total, issue|
      all_issues_total += issue.time_entries.all(:conditions => {:activity_id => activity.id}).sum(&:cost)
      all_issues_total
    end
  end

  # Total hours spent for a given activity
  def hours_spent_for_activity(activity)
    issue_ids = issues.collect(&:id)
    TimeEntry.sum(:hours,
                  :conditions => ["#{TimeEntry.table_name}.issue_id IN (?) AND activity_id IN (?)", issue_ids, activity.id])
  end

  # Total budget ($) for a given activity
  def budget_for_activity(activity)
    labor = labor_budgets.sum(:budget,
                              :conditions => ["#{LaborBudget.table_name}.time_entry_activity_id IN (?)", activity.id])
    overhead = overhead_budgets.sum(:budget,
                                    :conditions => ["#{OverheadBudget.table_name}.time_entry_activity_id IN (?)", activity.id])

    labor.to_f + overhead.to_f
  end
  
  # Total budget (hours) a given activity
  def hours_budget_for_activity(activity)
    labor = labor_budgets.sum(:hours,
                              :conditions => ["#{LaborBudget.table_name}.time_entry_activity_id IN (?)", activity.id])
    overhead = overhead_budgets.sum(:hours,
                                    :conditions => ["#{OverheadBudget.table_name}.time_entry_activity_id IN (?)", activity.id])

    labor.to_f + overhead.to_f
  end

  # Array of users who have logged billable time to the deliverable
  def users_with_billable_time
    users_with_time(true)
  end

  # Array of users who have logged non-billable time to the deliverable
  def users_with_non_billable_time
    users_with_time(false)
  end

  # Array of users who have logged a type of time to the deliverable
  #
  # @params billable_time_only Boolean Only count billable (true) or non-billable (false) time
  def users_with_time(billable_time_only)
    time_entries = project.time_entries.all(:conditions => ["#{TimeEntry.table_name}.issue_id IN (?)", issue_ids])

    time_entries.inject([]) do |users, time_entry|
      if time_entry.billable? == billable_time_only
        users << time_entry.user unless users.include?(time_entry.user)
      end
      users
    end
  end

  # Array of Issue Categories that have billable time logged
  def issue_categories_with_billable_time
    issue_categories_with_time(true)
  end

  # Array of Issue Categories that have non-billable time logged
  def issue_categories_with_non_billable_time
    issue_categories_with_time(false)
  end

  def issue_categories_with_time(billable_time_only)
    time_entries = project.time_entries.all(:conditions => ["#{TimeEntry.table_name}.issue_id IN (?)", issue_ids])

    time_entries.inject([]) do |categories, time_entry|
      if time_entry.billable? == billable_time_only && time_entry.issue.present? && time_entry.issue.category.present?
        categories << time_entry.issue.category unless categories.include?(time_entry.issue.category)
      end
      categories
    end
  end

  def spent_for_user(user, billable_time_only)
    time_entries = project.time_entries.all(:conditions => ["#{TimeEntry.table_name}.issue_id IN (?) AND #{TimeEntry.table_name}.user_id IN (?)", issue_ids, user.id])

    time_entries.select {|time| time.billable? == billable_time_only }.sum(&:cost)
  end

  def hours_spent_for_user(user, billable_time_only)
    time_entries = project.time_entries.all(:conditions => ["#{TimeEntry.table_name}.issue_id IN (?) AND #{TimeEntry.table_name}.user_id IN (?)", issue_ids, user.id])

    time_entries.select {|time| time.billable? == billable_time_only }.sum(&:hours)
  end

  def spent_for_issue_category(category, billable_time_only)
    time_entries = project.time_entries.all(:conditions => ["#{TimeEntry.table_name}.issue_id IN (?) AND #{Issue.table_name}.category_id IN (?)", issue_ids, category.id], :include => [:issue])

    time_entries.select {|time| time.billable? == billable_time_only }.sum(&:cost)
  end

  def hours_spent_for_issue_category(category, billable_time_only)
    time_entries = project.time_entries.all(:conditions => ["#{TimeEntry.table_name}.issue_id IN (?) AND #{Issue.table_name}.category_id IN (?)", issue_ids, category.id], :include => [:issue])

    time_entries.select {|time| time.billable? == billable_time_only }.sum(&:hours)
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

  # Required attribute for AAJ's JournalFormatter
  def name
    title
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
    generator_for :status, 'open'
    
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
