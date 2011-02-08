module RedmineContracts
  module Hooks
    class ControllerIssuesBulkEditBeforeSaveHook < Redmine::Hook::ViewListener
      # Context:
      # * :issue => Issue being saved
      # * :params => HTML parameters
      #
      def controller_issues_bulk_edit_before_save(context={})
        return '' unless User.current.allowed_to?(:assign_deliverable_to_issue, context[:issue].project)
        
        case
        when context[:params][:deliverable_id].blank?
          # Do nothing
        when context[:params][:deliverable_id] == 'none'
          # Unassign deliverable
          context[:issue].deliverable = nil
        else
          context[:issue].deliverable = Deliverable.find(context[:params][:deliverable_id])
        end
        
        return ''
      end
    end
  end
end
