class Contract < ActiveRecord::Base
  unloadable
  extend ActiveSupport::Memoizable

  ViewPrecision = 0

  # Associations
  belongs_to :project
  belongs_to :account_executive, :class_name => 'User', :foreign_key => 'account_executive_id'
  belongs_to :payment_term, :class_name => "PaymentTerm", :foreign_key => "payment_term_id"
  has_many :deliverables, :dependent => :destroy

  # Validations
  validates_presence_of :name
  validates_presence_of :account_executive
  validates_presence_of :project
  validates_presence_of :start_date
  validates_presence_of :end_date
  validates_inclusion_of :discount_type, :in => %w($ %), :allow_blank => true, :allow_nil => true
  validate :start_and_end_date_are_valid

  # Accessors
  attr_accessible :name
  attr_accessible :account_executive_id
  attr_accessible :start_date
  attr_accessible :end_date
  attr_accessible :executed
  attr_accessible :billable_rate
  attr_accessible :discount
  attr_accessible :discount_note
  attr_accessible :payment_term_id
  attr_accessible :client_ap_contact_information
  attr_accessible :po_number
  attr_accessible :client_point_of_contact
  attr_accessible :details

  named_scope :by_name, {:order => "#{Contract.table_name}.name ASC"}
  
  [:status, :contract_type,
   :discount_spent, :discount_budget
  ].each do |mthd|
    define_method(mthd) { "TODO in later release" }
  end

  # OPTIMIZE: N+1
  def labor_budget
    summarize_associated_values(deliverables, :labor_budget_total)
  end
  memoize :labor_budget

  # OPTIMIZE: N+1
  # OPTIMIZE: also hits redmine_overhead which is known to be slow
  def labor_spent
    summarize_associated_values(deliverables, :labor_budget_spent)
  end
  memoize :labor_spent

  # OPTIMIZE: N+1
  def labor_hour_budget
    summarize_associated_values(deliverables, :labor_budget_hours)
  end
  memoize :labor_hour_budget

  # OPTIMIZE: N+1
  # OPTIMIZE: also hits redmine_overhead which is known to be slow
  def labor_hour_spent
    summarize_associated_values(deliverables, :labor_hours_spent_total)
  end
  memoize :labor_hour_spent

  # OPTIMIZE: N+1
  def overhead_budget
    summarize_associated_values(deliverables, :overhead_budget_total)
  end
  memoize :overhead_budget

  # OPTIMIZE: N+1
  # OPTIMIZE: also hits redmine_overhead which is known to be slow
  def overhead_spent
    summarize_associated_values(deliverables, :overhead_spent)
  end
  memoize :overhead_spent

  # OPTIMIZE: N+1
  def overhead_hour_budget
    summarize_associated_values(deliverables, :overhead_budget_hours)
  end
  memoize :overhead_hour_budget

  # OPTIMIZE: N+1
  # OPTIMIZE: also hits redmine_overhead which is known to be slow
  def overhead_hour_spent
    summarize_associated_values(deliverables, :overhead_hours_spent_total)
  end
  memoize :overhead_hour_spent

  # OPTIMIZE: N+1
  def estimated_hour_budget
    summarize_associated_values(deliverables, :estimated_hour_budget_total)
  end
  memoize :estimated_hour_budget

  # OPTIMIZE: N+1
  def estimated_hour_spent
    summarize_associated_values(deliverables, :hours_spent_total)
  end
  memoize :estimated_hour_spent

  # OPTIMIZE: N+1
  def total_budget
    summarize_associated_values(deliverables, :total)
  end
  memoize :total_budget

  # OPTIMIZE: N+1
  def total_spent
    summarize_associated_values(deliverables, :total_spent)
  end
  memoize :total_spent

  # OPTIMIZE: N+1
  def profit_budget
    summarize_associated_values(deliverables, :profit_budget)
  end
  memoize :profit_budget

  # OPTIMIZE: N+1
  def profit_left
    summarize_associated_values(deliverables, :profit_left)
  end
  alias_method :profit_spent, :profit_left
  memoize :profit_left

  # OPTIMIZE: N+1
  def fixed_budget
    summarize_associated_values(deliverables, :fixed_budget_total)
  end
  memoize :fixed_budget

  # OPTIMIZE: N+1
  def fixed_spent
    summarize_associated_values(deliverables, :fixed_budget_total_spent)
  end
  memoize :fixed_spent

  # OPTIMIZE: N+1
  def fixed_markup_budget
    summarize_associated_values(deliverables, :fixed_markup_budget_total)
  end
  memoize :fixed_markup_budget
  
  # OPTIMIZE: N+1
  def fixed_markup_spent
    summarize_associated_values(deliverables, :fixed_markup_budget_total_spent)
  end
  memoize :fixed_markup_spent
  
  def after_initialize
    self.executed = false unless self.executed.present?
  end

  def start_and_end_date_are_valid
    if start_date && end_date && end_date < start_date
      errors.add :end_date, :greater_than_start_date
    end
  end

  def orphaned_time
    @orphaned_time ||= project.time_entries.all(:include => [:issue => :deliverable],
                                                :conditions => "#{Issue.table_name}.deliverable_id IS NULL OR #{TimeEntry.table_name}.issue_id IS NULL").inject(0) do |total, time_entry|
      total += time_entry.cost
    end
  end

  def to_s
    name
  end

  if Rails.env.test?
    generator_for :name, :method => :next_name
    generator_for :executed => true
    generator_for(:start_date) { Date.yesterday }
    generator_for(:end_date) { Date.tomorrow }

    def self.next_name
      @last_name ||= 'Contract 0000'
      @last_name.succ!
    end

  end
  
  private
  
  # This is a potential N+1 method since value_method might be calculated
  def summarize_associated_values(records, value_method)
    records.inject(0) {|total, record| total += record.send(value_method)}
  end
    
end
