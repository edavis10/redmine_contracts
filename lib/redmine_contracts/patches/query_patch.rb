module RedmineContracts
  module Patches
    module QueryPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method_chain :available_filters, :deliverable
          alias_method_chain :available_filters, :contract

          alias_method_chain :sql_for_field, :contract
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        # TODO: Should have an API on the Redmine core for this
        def available_filters_with_deliverable
          @available_filters = available_filters_without_deliverable

          if project
            deliverable_filters = {
              "deliverable_id" => {
                :type => :list_optional,
                :order => 15,
                :values => project.deliverables.by_title.collect { |d| [d.title, d.id.to_s] }
              }
            }
            return @available_filters.merge(deliverable_filters)
          else
            return @available_filters
          end

        end

        # TODO: Should have an API on the Redmine core for this
        def available_filters_with_contract
          @available_filters = available_filters_without_contract

          if project
            contract_filters = {
              "contract_id" => {
                :type => :list_optional,
                :order => 16,
                :values => project.contracts.by_name.collect { |d| [d.name, d.id.to_s] }
              }
            }
            return @available_filters.merge(contract_filters)
          else
            return @available_filters
          end

        end

        def sql_for_field_with_contract(field, operator, value, db_table, db_field, is_custom_filter=false)
          if field != "contract_id"
            return sql_for_field_without_contract(field, operator, value, db_table, db_field, is_custom_filter)
          else
            # Contracts > Deliverables > Issue
            case operator
            when "="
              contracts = value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",")
              inner_select = "(SELECT id from deliverables where deliverables.contract_id IN (#{contracts}))"
              sql = "#{Issue.table_name}.deliverable_id IN (#{inner_select})"
            when "!"
              contracts = value.collect{|val| "'#{connection.quote_string(val)}'"}.join(",")
              inner_select = "(SELECT id from deliverables where deliverables.contract_id IN (#{contracts}))"
              sql = "(#{Issue.table_name}.deliverable_id IS NULL OR #{Issue.table_name}.deliverable_id NOT IN (#{inner_select}))"
            when "!*"
              # If it doesn't have a deliverable, it can't have a contract
              sql = "#{Issue.table_name}.deliverable_id IS NULL"
            when "*"
              # If it has a deliverable, it must have a contract
              sql = "#{Issue.table_name}.deliverable_id IS NOT NULL"
            end

            return sql
          end
        end

      end
    end
  end
end
