module RedmineContracts
  module Hooks
    class ViewIssuesFormDetailsBottomHook < Redmine::Hook::ViewListener
      def view_issues_form_details_bottom(context={})
        return ''
      end
    end
  end
end
