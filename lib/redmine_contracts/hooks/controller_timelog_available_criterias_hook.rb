module RedmineContracts
  module Hooks
    class ControllerTimelogAvailableCriteriasHook < Redmine::Hook::ViewListener
      def controller_timelog_available_criterias(context={})
        context[:available_criterias]["deliverable_id"] = {
          :sql => "#{Issue.table_name}.deliverable_id",
          :klass => Deliverable,
          :label => :field_deliverable
        }
        return ''
      end
    end
  end
end
