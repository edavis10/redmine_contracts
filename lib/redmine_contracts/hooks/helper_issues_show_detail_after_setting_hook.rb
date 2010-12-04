module RedmineContracts
  module Hooks
    class HelperIssuesShowDetailAfterSettingHook < Redmine::Hook::ViewListener
      # Deliverable changes for the journal use the Deliverable subject
      # instead of the id
      #
      # Context:
      # * :detail => Detail about the journal change
      #
      def helper_issues_show_detail_after_setting(context = { })
        # TODO Later: Overwritting the caller is bad juju
        if context[:detail].prop_key == 'deliverable_id'
          context[:detail].reload
          
          d = Deliverable.find_by_id(context[:detail].value)
          context[:detail].value = d.title if d.present? && d.title.present?

          d = Deliverable.find_by_id(context[:detail].old_value)
          context[:detail].old_value = d.title if d.present? && d.title.present?
        end
        ''
      end
    end
  end
end
