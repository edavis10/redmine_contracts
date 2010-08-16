# A RetainerDeliverable is an HourlyDeliverable that is renewed at
# regular calendar periods.  The Company bills a regular number of
# hours for a hourly rate whereby the budgets are reset over a
# regular cyclical period (often monthly).
class RetainerDeliverable < HourlyDeliverable
  unloadable

  # Associations

  # Validations
  ValidFrequencies = ["monthly", "quarterly"]
  validates_inclusion_of :frequency, :in => ValidFrequencies, :allow_nil => true, :allow_blank => true
  
  # Accessors

  # Callbacks

  def short_type
    'R'
  end

  def current_period
    'TODO'
  end

  def self.frequencies_to_select
    ValidFrequencies.collect {|f| [l("text_#{f}"), f]}
  end
end
