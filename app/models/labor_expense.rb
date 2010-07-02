class LaborExpense < ActiveRecord::Base
  unloadable

  # Associations
  belongs_to :deliverable

  # Validations
  validates_presence_of :hours
  validates_presence_of :budget
  validates_presence_of :deliverable

  # Accessors

  def budget=(v)
    if v.is_a? String
      write_attribute(:budget, v.gsub(/[$ ,]/, ''))
    else
      write_attribute(:budget, v)
    end
  end
end
