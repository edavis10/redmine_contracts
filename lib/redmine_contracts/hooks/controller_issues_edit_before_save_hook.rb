module RedmineContracts
  module Hooks
    class ControllerIssuesEditBeforeSaveHook < Redmine::Hook::ViewListener
      def controller_issues_edit_before_save(context={})

        if context[:params] && context[:params][:issue]
          if context[:params][:issue][:deliverable_id].present?
            deliverable = Deliverable.find_by_id(context[:params][:issue][:deliverable_id])
            if deliverable.contract.project == context[:issue].project
              context[:issue].deliverable = deliverable
            end

          else
            context[:issue].deliverable = nil
          end

        end

        return ''
      end

      alias_method :controller_issues_new_before_save, :controller_issues_edit_before_save
    end
  end
end
