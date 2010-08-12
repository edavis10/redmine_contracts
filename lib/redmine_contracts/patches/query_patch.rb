module RedmineContracts
  module Patches
    module QueryPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :available_filters, :deliverable
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        # TODO: Should have an API on the Redmine core for this
        def available_filters_with_deliverable
          @available_filters = available_filters_without_deliverable

          if project
            deliverable_filters = {
              "deliverable_id" => {
                :type => :list_optional,
                :order => 15,
                :values => project.deliverables.by_title.collect { |d| [d.title, d.id.to_s] }
              }
            }
            return @available_filters.merge(deliverable_filters)
          else
            return @available_filters
          end

        end
      end
    end
  end
end
