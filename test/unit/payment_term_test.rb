require File.dirname(__FILE__) + '/../test_helper'

class PaymentTermTest < ActiveSupport::TestCase
  include Redmine::I18n

  should_have_many(:contracts)
  
  should "be a subclass of Enumeration" do
    assert_equal Enumeration, PaymentTerm.superclass
  end

  context "#option_name" do
    should "be Payment Terms" do
      assert_equal "Payment Terms", l(PaymentTerm.new.option_name)
    end
  end

  context "#objects_count" do
    should "count the number of contracts with this payment term" do
      @payment_term = PaymentTerm.generate!(:type => 'PaymentTerm')
      Contract.generate!(:payment_term => @payment_term)
      Contract.generate!(:payment_term => @payment_term)

      assert_equal 2, @payment_term.objects_count
    end
  end

  context "#transfer_relations" do
    should "update all contracts to use a new PaymentTerm" do
      @old_payment_term = PaymentTerm.generate!(:type => 'PaymentTerm')
      @new_payment_term = PaymentTerm.generate!(:type => 'PaymentTerm')
      @contract1 = Contract.generate!(:payment_term => @old_payment_term)
      @contract2 = Contract.generate!(:payment_term => @old_payment_term)

      @old_payment_term.transfer_relations(@new_payment_term)
      assert_equal @new_payment_term, @contract1.reload.payment_term
      assert_equal @new_payment_term, @contract2.reload.payment_term
    end
  end
end
