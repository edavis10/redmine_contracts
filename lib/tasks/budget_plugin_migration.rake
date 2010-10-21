namespace :redmine_contracts do
  desc "Migrate data from the budget_plugin to redmine_contracts"
  task :budget_migration => :environment do
    options = {}
    options[:contract_rate] = ENV['contract_rate']
    options[:account_executive] = ENV['account_executive']
    options[:deliverable_manager] = ENV['deliverable_manager']
    options[:append_object_notes] = ENV['append_object_notes']
    options[:overhead_rate] = ENV['overhead_rate']
    
    RedmineContracts::BudgetPluginMigration.check_for_installed_budget_plugin
    data = RedmineContracts::BudgetPluginMigration.export_data
    RedmineContracts::BudgetPluginMigration.rename_old_tables
    RedmineContracts::BudgetPluginMigration.migrate_contracts
    RedmineContracts::BudgetPluginMigration.migrate(data, options)
  end
end
