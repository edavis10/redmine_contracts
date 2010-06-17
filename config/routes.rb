ActionController::Routing::Routes.draw do |map|
  map.resources :contracts, :path_prefix => '/projects/:project_id'
end
