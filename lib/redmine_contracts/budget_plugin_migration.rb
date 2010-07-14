module RedmineContracts

  # TODO: decide how this is activated.
  # Have the user dump yaml themselves?  Or rename the tables and
  # SQL select the data out into yaml?
  # Deliverable.all.collect {|d| d.attributes}.to_yaml
  class BudgetPluginMigration
    @@data = nil

    def self.migrate(old_data)
      @@data = old_data

      ActiveRecord::Base.transaction do
        @@data.each do |old_deliverable|

          deliverable = Deliverable.new(
                                        :title => old_deliverable['subject'],
                                        :end_date => old_deliverable['due'],
                                        :notes => old_deliverable['description']
                                        )
          deliverable.type = old_deliverable['type']

          project = Project.find(old_deliverable['project_id'])
          contract = Contract.find_by_project_id(project.id)
          if contract.nil?
            contract = Contract.new(:name => 'Converted Contract',
                                    :start_date => old_deliverable['due'],
                                    :end_date => old_deliverable['due'])

            
            contract.project = project
            contract.account_executive = project.users.first
            contract.save!
          end

          deliverable.contract = contract
          deliverable.manager = project.users.first          

          if old_deliverable['overhead'].present?
            deliverable.overhead_budgets << OverheadBudget.new(:deliverable => deliverable,
                                                               :budget => old_deliverable['overhead'],
                                                               :hours => 0)
          end
          
          case old_deliverable['type']
          when 'FixedDeliverable'
            deliverable.total = old_deliverable['fixed_cost']
          else
            # no-op
          end
          
          deliverable.save!
        end
      end
    end

    def self.data
      @@data
    end
  end
end
