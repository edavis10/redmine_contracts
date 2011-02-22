module RedmineContracts
  module Patches
    module IssuePatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          belongs_to :deliverable

          delegate :title, :to => :deliverable, :prefix => true, :allow_nil => true
          delegate :contract, :to => :deliverable, :allow_nil => true

          def contract_name
            contract.try(:name)
          end
        end
      end

      module ClassMethods
      end

      module InstanceMethods
      end
    end
  end
end
