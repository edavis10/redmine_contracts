config.gem 'formtastic', :version => '0.9.10'

require 'redmine'

Redmine::Plugin.register :redmine_contracts do
  name 'Redmine Contracts plugin'
  author 'Eric Davis'
  description 'A system to manage the execution of a client contract by separating it into deliverables and milestones.'
  url 'https://projects.littlestreamsoftware.com/projects/redmine-contracts'
  author_url 'http://www.littlestreamsoftware.com'
  version '0.1.0'

  requires_redmine :version_or_higher => '0.9.0'
  requires_redmine_plugin :redmine_rate, :version_or_higher => '0.1.0'

  project_module :contracts do
    permission :manage_budget, {:contracts => [:index, :new, :create, :show] }, :public => true
  end

  menu(:project_menu,
       :contracts,
       {:controller => 'contracts', :action => 'index'},
       :caption => :text_contracts,
       :param => :project_id)

  menu(:project_menu,
       :new_contract,
       {:controller => 'contracts', :action => 'new'},
       :caption => :text_new_contract,
       :param => :project_id,
       :parent => :contracts)

end

require 'dispatcher'
Dispatcher.to_prepare :redmine_contracts do

  gem 'inherited_resources', :version => '1.0.6'
  require_dependency 'inherited_resources'
  require_dependency 'inherited_resources/base'

  # Load and bootstrap formtastic
  gem 'formtastic', :version => '0.9.10'
  require_dependency 'formtastic'
  require_dependency 'formtastic/layout_helper'
  ActionView::Base.send :include, Formtastic::SemanticFormHelper
  ActionView::Base.send :include, Formtastic::LayoutHelper

  Formtastic::SemanticFormBuilder.all_fields_required_by_default = false
  Formtastic::SemanticFormBuilder.required_string = "<span class='required'> *</span>"
  
  require_dependency 'project'
  Project.send(:include, RedmineContracts::Patches::ProjectPatch)
end
