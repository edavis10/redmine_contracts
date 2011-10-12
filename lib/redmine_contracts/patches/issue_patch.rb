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

          # ChiliProject 2.x support for acts_as_journalized.
          # Used to format the journal details on the Issue page
          #
          # See RedmineContracts::Hooks::HelperIssuesShowDetailAfterSettingHook
          # for <2.x and Redmine version
          #
          # TODO: Will not support permissions or custom code in the formatter.
          if Issue.respond_to?(:register_on_journal_formatter)
            register_on_journal_formatter(:named_association, 'deliverable_id')
          end
          
          def contract_name
            contract.try(:name)
          end

          validate :validate_deliverable_status
          validate :validate_contract_status

          def validate_deliverable_status
            if deliverable.present? && changes["deliverable_id"].present?
              errors.add_to_base(:cant_assign_to_closed_deliverable) if deliverable.closed?
              errors.add_to_base(:cant_assign_to_locked_deliverable) if deliverable.locked?
            end
          end

          def validate_contract_status
            if deliverable.present? && changes["deliverable_id"].present? && contract.present?
              errors.add_to_base(:cant_assign_to_closed_contract) if contract.closed?
              errors.add_to_base(:cant_assign_to_locked_contract) if contract.locked?
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
