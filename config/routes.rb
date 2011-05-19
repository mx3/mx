Edge::Application.routes.draw do |map|

    # Some non-RESTfull API calls
  map.connect '/projects/:proj_id/api/ontology/obo_file', :action => :obo_file, :controller => 'api/ontology'  # mode is row or col
  map.connect '/projects/:proj_id/api/ontology/class_depictions', :action => :class_depictions, :controller => 'api/ontology'  # mode is row or col
  map.connect 'api/ontology/obo_file', :action => :obo_file, :controller => 'api/ontology'  # mode is row or col
  map.connect 'api/ontology/class_depictions', :action => :class_depictions, :controller => 'api/ontology'  # mode is row or col

  map.namespace  :api, :only => [:index, :show] do |api|
   api.resources :figure
   api.resources :ontology
   api.resources :ref
  end

  # handles development non-api calls
  map.namespace :api, :path_prefix => '/projects/:proj_id/api', :only => [:index, :show] do |api|
   api.resources :figure
   api.resources :ontology
   api.resources :ref
  end

  # map.connect '/projects/:proj_id/api/:controller/:id',
  # map.connect '/projects/:proj_id/api/:controller/:action.:format'
  # map.connect '/projects/:proj_id/api/:controller/:action',
  #   :requirements => {:action => /[A-Za-z_]+/}

  # matrix/coding routes
  map.connect '/projects/:proj_id/:controller/fast_code/:id/:mode/:position/:otu_id/:chr_id/:chr_state_id', :action => 'fast_code'  # mode is row or col
  map.connect '/projects/:proj_id/:controller/fast_code/:id/:mode/:position/:otu_id/:chr_id', :action => 'fast_code'
  map.connect '/projects/:proj_id/:controller/code/:id/:otu_id/:chr_id', :action => 'show_code' # for cell clicks

  # associations
  map.connect '/projects/:proj_id/:controller/:action/association/:association_id/:id',
    :requirements => {  :proj_id => /\d+/,
                        :id => /\d+/}

  # content
   map.connect '/projects/:proj_id/:controller/edit_page/:id/:content_template_id',
      :requirements => {:proj_id => /\d+/,
                        :id => /\d+/,
                        :content_template_id => /\d+/},
      :action => 'edit_page'

  map.connect '/projects/:proj_id/:controller/:action/:id/:con_template_id',
      :requirements => {:proj_id => /\d+/,
                        :id => /\d+/,
                        :con_template_id => /\d+/}


  # handle project controller prefix (this is hit on public requests)
#  map.connect 'projects/:proj_id/:controller/:action/:id.:format',
#    :controller => 'proj'

  # TODO :format be optional (.resources likely)
#  map.connect 'projects/:proj_id/:controller/:action/:id',
#    :controller => 'proj'

 # map.connect '/projects/:proj_id/:controller/:action.:format'
 # map.connect '/projects/:proj_id/:controller/:action'


  # Install the default route as the lowest priority.
  # this handles just :controller and :controller/:action as well
  # the proj part on the end says that if the controller was not specified in the request
  # (i.e. ''), call the proj controller (the :index action is default for it)
 #  map.connect ':controller/:action/:id.:format',
 #    :controller => 'proj',
 #    :requirements => {:action => /[A-Za-z_]+/}

 # map.connect ':controller/:action/:id',
 #   :controller => 'proj',
 #   :requirements => {:action => /[A-Za-z_]+/}

 # match 'projects/:proj_id/public/:controller(/:action(/:id(.:format)))'
  match 'projects/:proj_id/:controller(/:action(/:id(.:format)))'
  match ':controller(/:action(/:id(.:format)))'
 
  
  # match 'projects/:id', :to => "proj#index", :via => 'get'

  map.connect "*anything",
   :controller => "application",
   :action => "index",
   :unresolvable => 'true'  


  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "proj#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
#  match ':controller(/:action(/:id(.:format)))'
end
