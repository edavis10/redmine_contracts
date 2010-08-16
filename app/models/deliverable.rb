class Deliverable < ActiveRecord::Base
  unloadable

  ViewPrecision = 2
  
  # Associations
  belongs_to :contract
  belongs_to :manager, :class_name => 'User', :foreign_key => 'manager_id'
  has_many :labor_budgets
  has_many :overhead_budgets
  has_many :issues

  accepts_nested_attributes_for :labor_budgets
  accepts_nested_attributes_for :overhead_budgets
  
  # Validations
  validates_presence_of :title
  validates_presence_of :type
  validates_presence_of :manager
  
  # Accessors

  delegate :name, :to => :contract, :prefix => true, :allow_nil => true

  named_scope :by_title, {:order => "#{Deliverable.table_name}.title ASC"}
  
  def short_type
    ''
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

  def labor_budget_total
    labor_budgets.sum(:budget)
  end

  def overhead_budget_total
    overhead_budgets.sum(:budget)
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

  # Wrapper for the old Budget plugins' API
  def due
    end_date
  end

  def retainer?
    type == "RetainerDeliverable"
  end

  if Rails.env.test?
    generator_for :title, :method => :next_title

    def self.next_title
      @last_title ||= 'Deliverable 0000'
      @last_title.succ!
    end

  end
  
end
