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
          delegate :contract_name, :to => :deliverable, :allow_nil => true
        end
      end

      module ClassMethods
      end

      module InstanceMethods
      end
    end
  end
end
