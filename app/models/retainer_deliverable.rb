# A RetainerDeliverable is an HourlyDeliverable that is renewed at
# regular calendar periods.  The Company bills a regular number of
# hours for a hourly rate whereby the budgets are reset over a
# regular cyclical period (often monthly).
class RetainerDeliverable < HourlyDeliverable
  unloadable

end
