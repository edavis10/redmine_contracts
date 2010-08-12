class PopulatePaymentTerms < ActiveRecord::Migration
  def self.up
    [0, 15, 30, 45, 60, 75, 90].each_with_index do |days, index|
      name = "Net #{days}"
      unless PaymentTerm.find_by_name(name)
        PaymentTerm.create!(:name => name, :position => index + 1)
      end
    end
  end

  def self.down
    # No-op
  end
end
