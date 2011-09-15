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
          activities.partition do |activity|
            activity.billable?
          end.first
        end
      end
    end
  end
end
