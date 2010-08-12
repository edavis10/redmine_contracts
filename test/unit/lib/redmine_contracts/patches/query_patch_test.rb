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
    end
  end
  
end
