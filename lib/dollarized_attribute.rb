# Shared module to allow seting an attribute using:
# * Dollar amount - $1,000.00
# * Number - 100.00
module DollarizedAttribute
  module ClassMethods
    
    # dollarized_attribute(:budget) will create a budget=(value) method
    def dollarized_attribute(attribute)
      define_method(attribute.to_s + '=') {|value|
        if value.is_a? String
          write_attribute(attribute, value.gsub(/[$ ,]/, ''))
        else
          write_attribute(attribute, value)
        end
      }
    end
    
  end

  def self.included(base)
    base.extend ClassMethods
  end
end
