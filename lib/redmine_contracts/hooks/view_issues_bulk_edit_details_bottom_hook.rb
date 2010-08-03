module RedmineContracts
  module Hooks
    class ViewIssuesBulkEditDetailsBottomHook < Redmine::Hook::ViewListener

      render_on(:view_issues_bulk_edit_details_bottom, :partial => 'issues/bulk_edit_deliverable', :layout => false)

    end
  end
end
