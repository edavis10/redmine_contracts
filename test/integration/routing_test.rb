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
  
end
