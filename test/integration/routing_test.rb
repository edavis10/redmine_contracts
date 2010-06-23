require 'test_helper'

class RoutingTest < ActionController::IntegrationTest
  context "contracts" do
    should_route :get, "/projects/world_domination/contracts", :controller => 'contracts', :action => 'index', :project_id => 'world_domination'
    should_route :get, "/projects/world_domination/contracts/new", :controller => 'contracts', :action => 'new', :project_id => 'world_domination'
    should_route :get, "/projects/world_domination/contracts/1", :controller => 'contracts', :action => 'show', :id => '1', :project_id => 'world_domination'
    should_route :get, "/projects/world_domination/contracts/1/edit", :controller => 'contracts', :action => 'edit', :id => '1', :project_id => 'world_domination'

    should_route :post, "/projects/world_domination/contracts", :controller => 'contracts', :action => 'create', :project_id => 'world_domination'

    should_route :put, "/projects/world_domination/contracts/1", :controller => 'contracts', :action => 'update', :id => '1', :project_id => 'world_domination'

    should_route :delete, "/projects/world_domination/contracts/1", :controller => 'contracts', :action => 'destroy', :id => '1', :project_id => 'world_domination'
  end
  
  context "deliverables" do
    should_route :get, "/projects/world_domination/contracts/1/deliverables", :controller => 'deliverables', :action => 'index', :project_id => 'world_domination', :contract_id => '1'
    should_route :get, "/projects/world_domination/contracts/1/deliverables/new", :controller => 'deliverables', :action => 'new', :project_id => 'world_domination', :contract_id => '1'
    should_route :get, "/projects/world_domination/contracts/1/deliverables/10", :controller => 'deliverables', :action => 'show', :id => '10', :project_id => 'world_domination', :contract_id => '1'
    should_route :get, "/projects/world_domination/contracts/1/deliverables/10/edit", :controller => 'deliverables', :action => 'edit', :id => '10', :project_id => 'world_domination', :contract_id => '1'

    should_route :post, "/projects/world_domination/contracts/1/deliverables", :controller => 'deliverables', :action => 'create', :project_id => 'world_domination', :contract_id => '1'

    should_route :put, "/projects/world_domination/contracts/1/deliverables/10", :controller => 'deliverables', :action => 'update', :id => '10', :project_id => 'world_domination', :contract_id => '1'

    should_route :delete, "/projects/world_domination/contracts/1/deliverables/10", :controller => 'deliverables', :action => 'destroy', :id => '10', :project_id => 'world_domination', :contract_id => '1'
  end
end
