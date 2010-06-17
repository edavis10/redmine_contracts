class Contract < ActiveRecord::Base
  unloadable

  # Associations
  belongs_to :project
  belongs_to :account_executive, :class_name => 'User', :foreign_key => 'account_executive_id'

  # Validations
  validates_presence_of :name
  validates_presence_of :account_executive
  validates_presence_of :project
  validates_presence_of :start_date
  validates_presence_of :end_date
  validates_presence_of :executed
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
  attr_accessible :payment_terms
  attr_accessible :client_ap_contact_information
  attr_accessible :po_number
  attr_accessible :details

  def after_initialize
    self.executed = false unless self.executed.present?
  end

  def start_and_end_date_are_valid
    if start_date && end_date && end_date < start_date
      errors.add :end_date, :greater_than_start_date
    end
  end
end
