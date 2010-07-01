module RedmineContracts
  module Hooks
    class ViewLayoutsBaseHtmlHeadHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context={})
        if context[:controller] && (
                                    context[:controller].is_a?(ContractsController) ||
                                    context[:controller].is_a?(DeliverablesController)
                                    )
          return stylesheet_link_tag("redmine_contracts", :plugin => "redmine_contracts", :media => "screen") +

            javascript_include_tag('jquery-1.4.2.min.js', :plugin => 'redmine_contracts') +
            javascript_include_tag('contracts.js', :plugin => 'redmine_contracts')

        else
          return ''
        end
      end
    end
  end
end
