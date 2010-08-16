module RedmineContracts
  module Hooks
    class ControllerTimelogAvailableCriteriasHook < Redmine::Hook::ViewListener
      def controller_timelog_available_criterias(context={})
        context[:available_criterias]["deliverable_id"] = {
          :sql => "#{Issue.table_name}.deliverable_id",
          :klass => Deliverable,
          :label => :field_deliverable
        }
        context[:available_criterias]["contract_id"] = {
          :sql => "(SELECT deliverable.contract_id FROM #{Deliverable.table_name} deliverable WHERE deliverable.id = issues.deliverable_id)",
          :klass => Contract,
          :label => :field_contract
        }
        return ''
      end
    end
  end
end
