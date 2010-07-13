module RedmineContracts

  # TODO: decide how this is activated.
  # Have the user dump yaml themselves?  Or rename the tables and
  # SQL select the data out into yaml?
  # Deliverable.all.collect {|d| d.attributes}.to_yaml
  class BudgetPluginMigration
    @@data = nil

    def self.migrate(old_data)
      @@data = old_data
    end

    def self.data
      @@data
    end
  end
end
