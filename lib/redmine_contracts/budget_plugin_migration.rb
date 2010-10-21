module RedmineContracts
  class BudgetPluginInstalledError < StandardError; end

  class BudgetPluginDeliverable < ActiveRecord::Base
    set_table_name 'deliverables'
  end
  
  class BudgetPluginMigration
    @@data = nil

    def self.check_for_installed_budget_plugin
      if Redmine::Plugin.registered_plugins.keys.include?(:budget_plugin)
        raise BudgetPluginInstalledError, "The budget plugin is still installed. Please remove it and retry the conversion"
      end
    end

    def self.rename_old_tables
      ActiveRecord::Migration.rename_table(:deliverables, :budget_plugin_deliverables)
      Deliverable.reset_column_information
      RedmineContracts::BudgetPluginDeliverable.reset_column_information      
    end

    def self.export_data
      RedmineContracts::BudgetPluginDeliverable.all.collect {|d| d.attributes}.to_yaml
    end

    def self.migrate_contracts
      ::Engines.plugins['redmine_contracts'].migrate
    end

    # * old_data - YAML string of deliverables to migrate
    #
    # @param [Hash] options the options to migrate with
    # @option options [String] :contract_rate the contract rate to use. Defaults to 150.0
    # @option options [String] :account_executive the id or login of the user
    #                          to use for the contract account executive
    #                          Defaults to the first user on the project.
    # @option options [String] :deliverable_manager the id or login of the user
    #                          to use for the deliverables manager
    #                          Defaults to the first user on the project.
    # @option options [boolean] :append_object_notes show the old Budget data be
    #                           added to the Deliverable notes (for debugging)
    #                           Defaults to true (will append)
    # @option options [float] :overhead_rate the overhead rate to use when calculating hours.
    #                         Defaults to 0
    def self.migrate(old_data, options={})
      @contract_rate = options[:contract_rate] ? options[:contract_rate].to_f : 150.0
      @account_executive = if options[:account_executive].present?
                             user = User.find_by_login(options[:account_executive])
                             user ||= User.find_by_id(options[:account_executive])
                           end
      @deliverable_manager = if options[:deliverable_manager].present?
                               user = User.find_by_login(options[:deliverable_manager])
                               user ||= User.find_by_id(options[:deliverable_manager])
                             end

      @append_object_notes = if options[:append_object_notes].nil?
                               true
                             else
                               # Simple option parsing
                               if options[:append_object_notes] == false ||
                                   options[:append_object_notes] == 'false' ||
                                   options[:append_object_notes] == 0 ||
                                   options[:append_object_notes] == '0'
                                 false
                               else
                                 true
                               end
                             end
      @overhead_rate = options[:overhead_rate].nil? ? 0 : options[:overhead_rate].to_f
      
      @@data = YAML.load(old_data)

      # Map old deliverable ids to the new ones
      @deliverable_mapper = {}
      
      ActiveRecord::Base.transaction do
        @@data.each do |old_deliverable|

          deliverable = Deliverable.new(
                                        :title => old_deliverable['subject'],
                                        :end_date => old_deliverable['due'],
                                        :notes => old_deliverable['description']
                                        )
          # All deliverables are converted over to FixedDeliverable
          deliverable.type = 'FixedDeliverable'
          project = Project.find(old_deliverable['project_id'])
          contract = Contract.find_by_project_id(project.id)
          contract ||= create_new_contract(old_deliverable)

          deliverable.contract = contract
          deliverable.manager = @deliverable_manager || project.users.first
          deliverable.total = old_deliverable['budget']
          
          case old_deliverable['type']
          when 'FixedDeliverable'
            @total_cost = old_deliverable['fixed_cost']
            convert_old_fixed_deliverable_to_fixed_budgets(deliverable, old_deliverable)
            
          when 'HourlyDeliverable'
            @total_cost = old_deliverable['total_hours'].to_f * old_deliverable['cost_per_hour'].to_f

            if old_deliverable['total_hours'].present? || old_deliverable['cost_per_hour'].present?
              deliverable.labor_budgets << LaborBudget.new(:deliverable => deliverable,
                                                           :budget => @total_cost,
                                                           :hours => old_deliverable['total_hours'])
            end
          else
            @total_cost = 0
          end

          convert_overhead(deliverable, old_deliverable, @total_cost)
          convert_materials(deliverable, old_deliverable, @total_cost)
          append_old_deliverable_to_notes(old_deliverable, deliverable) if @append_object_notes
          
          deliverable.save!
          
          @deliverable_mapper[old_deliverable['id']] = deliverable.id
        end
      end

      # Slower than update_all but update_all could potentially hit an issue
      # multiple times depending on the migration order. Example:
      #
      # - Issue 1 has Deliverable 1
      # - Deliverable 1 updates Issue 1 to have the new deliverable id of 3
      # - Deliverable 3 runs and updates Issue 1 again to have the new deliverable id of 5
      #
      Issue.all.each do |issue|
        next if issue.deliverable_id.blank?

        issue.update_attribute(:deliverable_id, @deliverable_mapper[issue.deliverable_id])
      end
    end

    def self.data
      @@data
    end

    private

    def self.create_new_contract(old_deliverable)
      project = Project.find(old_deliverable['project_id'])

      contract = Contract.new(:name => 'Converted Contract',
                              :start_date => old_deliverable['due'],
                              :end_date => old_deliverable['due']) do |c|
        c.project = project
        c.account_executive = @account_executive || project.users.first
        c.start_date ||= Date.today
        c.end_date ||= Date.today
        c.billable_rate = @contract_rate
      end

      contract.save!
      unless project.module_enabled?(:contracts)
        EnabledModule.create!(:project => project, :name => 'contracts')
      end
      contract
    end

    def self.convert_overhead(deliverable, old_deliverable, total)
      total ||= 0
      if old_deliverable['overhead'].present?
        if @overhead_rate != 0
          hours = old_deliverable['overhead'] / @overhead_rate
        else
          hours = 0
        end
        
        deliverable.overhead_budgets << OverheadBudget.new(:deliverable => deliverable,
                                                           :budget => old_deliverable['overhead'],
                                                           :hours => hours.to_f.round(2))
      elsif old_deliverable['overhead_percent'].present?
        overhead = total * (old_deliverable['overhead_percent'].to_f / 100)
        if @overhead_rate != 0
          hours = overhead / @overhead_rate
        else
          hours = 0
        end
          
        deliverable.overhead_budgets << OverheadBudget.new(:deliverable => deliverable,
                                                           :budget => overhead,
                                                           :hours => hours.to_f.round(2))

      end
    end
    
    def self.convert_materials(deliverable, old_deliverable, total)
      total ||= 0
      
      if old_deliverable['materials'].present? && old_deliverable['materials'] > 0.0
        deliverable.fixed_budgets << FixedBudget.new(:deliverable => deliverable,
                                                     :budget => old_deliverable['materials'],
                                                     :markup => 0)

      elsif old_deliverable['materials_percent'].present? && old_deliverable['materials_percent'] > 0.0
        materials = total * (old_deliverable['materials_percent'].to_f / 100)
        deliverable.fixed_budgets << FixedBudget.new(:deliverable => deliverable,
                                                     :budget => materials,
                                                     :markup => 0)

      end
    end

    def self.convert_old_fixed_deliverable_to_fixed_budgets(deliverable, old_deliverable)
      if old_deliverable['fixed_cost'].present?
        budget = old_deliverable['fixed_cost']
      else
        budget = 0
      end

      if old_deliverable['profit'].present?
        markup = old_deliverable['profit']
      elsif old_deliverable['profit_percent'].present?
        markup = old_deliverable['profit_percent'].to_s + "%"
      else
        markup = '0'
      end
      
      deliverable.fixed_budgets << FixedBudget.new(:deliverable => deliverable,
                                                   :budget => budget,
                                                   :markup => markup,
                                                   :title => "Converted Fixed Deliverable - #{old_deliverable['subject']}")
      
    end

    def self.append_old_deliverable_to_notes(old_deliverable, new_deliverable)
      new_deliverable.notes += "Converted data:\n<pre>" + old_deliverable.pretty_inspect + "</pre>"
    end
  end
end
