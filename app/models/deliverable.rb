class Deliverable < ActiveRecord::Base
  unloadable

  # Associations
  belongs_to :contract
  belongs_to :manager, :class_name => 'User', :foreign_key => 'manager_id'

  # Validations
  validates_presence_of :title
  validates_presence_of :type
  validates_presence_of :manager
  
  # Accessors

  def short_type
    ''
  end

  def total=(v)
    if v.is_a? String
      write_attribute(:total, v.gsub(/[$ ,]/, ''))
    else
      write_attribute(:total, v)
    end
  end
  
  if Rails.env.test?
    generator_for :title, :method => :next_title

    def self.next_title
      @last_title ||= 'Deliverable 0000'
      @last_title.succ!
    end

  end
  
end
