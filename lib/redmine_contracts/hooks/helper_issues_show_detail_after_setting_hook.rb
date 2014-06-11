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
        # This will be skipped in ChiliProject 2.x because
        # acts_as_journalized overrides the prop_key with the label
        # 'deliverable_id' becomes 'Deliverable' (i18n)
        #
        # register_on_journal_formatter is used for ChiliProject 2.x support
        # TODO Later: Overwritting the caller is bad juju
        if context[:detail].prop_key == 'deliverable_id'
          context[:detail].reload
          
          d = Deliverable.find_by_id(context[:detail].value)
          context[:detail].value = d.title if d.try(:title)

          d = Deliverable.find_by_id(context[:detail].old_value)
          context[:detail].old_value = d.title if d.try(:title)
        end
        ''
      end
    end
  end
end
