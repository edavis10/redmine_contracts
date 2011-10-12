module RedmineContracts
  module Patches
    module ProjectPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          has_many :contracts
          has_many :deliverables, :through => :contracts
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def billable_activities
          activities_sorted_by_billable[:billable]
        end

        def non_billable_activities
          activities_sorted_by_billable[:non_billable]
        end

        private

        def activities_sorted_by_billable
          split_activities = activities.partition do |activity|
            activity.billable?
          end

          {
            :billable => split_activities.first,
            :non_billable => split_activities.second
          }

        end
      end
    end
  end
end
