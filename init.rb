require 'redmine'

Redmine::Plugin.register :redmine_contracts do
  name 'Redmine Contracts plugin'
  author 'Eric Davis'
  description 'A system to manage the execution of a client contract by separating it into deliverables and milestones.'
  url 'https://projects.littlestreamsoftware.com/projects/redmine-contracts'
  author_url 'http://www.littlestreamsoftware.com'
  version '0.1.0'
  requires_redmine :version_or_higher => '0.9.0'
end
