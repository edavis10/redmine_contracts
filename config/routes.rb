ActionController::Routing::Routes.draw do |map|
  map.resources :contracts, :path_prefix => '/projects/:project_id' do |contracts|
    contracts.resources :deliverables
  end
end
