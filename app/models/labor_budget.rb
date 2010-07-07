class LaborBudget < ActiveRecord::Base
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
end
