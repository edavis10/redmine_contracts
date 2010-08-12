class PaymentTerm < Enumeration
  unloadable

  has_many :contracts, :foreign_key => 'payment_term_id'

  OptionName = :enumeration_payment_term
  
  def option_name
    OptionName
  end

  def objects_count
    contracts.count
  end

  def transfer_relations(to)
    contracts.update_all("payment_term_id = #{to.id}")
  end
end
