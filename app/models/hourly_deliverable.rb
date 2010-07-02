class HourlyDeliverable < Deliverable
  unloadable

  # Associations

  # Validations

  # Accessors

  # Callbacks
  before_save :clear_total

  def short_type
    'H'
  end

  # Block getting and setting the total on HourlyDeliverables
  def total
    nil
  end
  
  def total=(v)
    nil
  end

  def clear_total
    write_attribute(:total, nil)
  end
end
