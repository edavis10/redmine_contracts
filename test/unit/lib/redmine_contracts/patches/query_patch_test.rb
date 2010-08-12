require File.dirname(__FILE__) + '/../../../../test_helper'

class RedmineContracts::Patches::QueryTest < ActionController::TestCase

  context "Query" do
    subject {Query.new}

    context "#available_filters with project" do
      setup do
        @query = Query.new
        @query.project = @project = Project.generate!
        @contract = Contract.generate!(:project => @project, :name => 'A Contract')
        @manager = User.generate!
        @deliverable1 = FixedDeliverable.generate!(:contract => @contract, :manager => @manager, :title => 'One')
        @deliverable2 = FixedDeliverable.generate!(:contract => @contract, :manager => @manager, :title => 'Two')
      end
      
      should "add a deliverable_id filter" do
        filters = @query.available_filters

        assert filters.keys.include?("deliverable_id")

        deliverable_filter = filters["deliverable_id"]
        assert_equal :list_optional, deliverable_filter[:type]
        assert_equal [
                      ["One", @deliverable1.id.to_s],
                      ["Two", @deliverable2.id.to_s]
                     ], deliverable_filter[:values]
      end

      should "add a contract_id filter" do
        filters = @query.available_filters

        assert filters.keys.include?("contract_id")

        contract_filter = filters["contract_id"]
        assert_equal :list_optional, contract_filter[:type]
        assert_equal [["A Contract", @contract.id.to_s]], contract_filter[:values]
      end
    end

    # TODO: Dragons in this test
    context "#sql_for_field_with_contract" do
      context "for contract_id fields" do
        setup do
          @query = Query.new
        end
        
        context "with the equal operator" do
          should "return the SQL snippet for checking for deliverables on the specific contracts" do
            sql = @query.send(:sql_for_field, 'contract_id', '=', ['1','2'], '', '')
            assert_equal "issues.deliverable_id IN ((SELECT id from deliverables where deliverables.contract_id IN ('1','2')))", sql
          end
        end

        context "with is not operator" do
          should "return the SQL snippet for checking for null deliverables or deliverables no on the specific contracts" do
            sql = @query.send(:sql_for_field, 'contract_id', '!', ['1','2'], '', '')
            assert_equal "(issues.deliverable_id IS NULL OR issues.deliverable_id NOT IN ((SELECT id from deliverables where deliverables.contract_id IN ('1','2'))))", sql
            end
        end

        context "with none operator" do
          should "return the SQL snippet for checking for null deliverables" do
            sql = @query.send(:sql_for_field, 'contract_id', '!*', '', '', '')
            assert_equal "issues.deliverable_id IS NULL", sql
          end
        end

        context "with all operator" do
          should "return the SQL snippet for checking for not null deliverables" do
            sql = @query.send(:sql_for_field, 'contract_id', '*', '', '', '')
            assert_equal "issues.deliverable_id IS NOT NULL", sql
          end
        end
        

      end
    end

  end
  
end
