module RedmineContracts
  module Patches
    module TimeEntryPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          validate :validate_deliverable_status
          validate :validate_contract_status

          def validate_deliverable_status
            if issue.present? && issue.deliverable.present?
              errors.add_to_base(:cant_create_time_on_closed_deliverable) if issue.deliverable.closed?
            end
          end

          def validate_contract_status
            if issue.present? && issue.deliverable.present? && issue.deliverable.contract.present?
              errors.add_to_base(:cant_create_time_on_closed_contract) if issue.deliverable.contract.closed?
            end
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
