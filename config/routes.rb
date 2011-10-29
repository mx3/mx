Edge::Application.routes.draw do

  root :to => "proj#index"

  # Some non-RESTfull API calls
  match "/projects/:proj_id/api/ontology/obo_file", :action => :obo_file, :controller => "api/ontology"
  match "/projects/:proj_id/api/ontology/class_depictions", :action => :class_depictions, :controller => "api/ontology"
  match "api/ontology/obo_file", :action => :obo_file, :controller => "api/ontology"
  match "api/ontology/class_depictions", :action => :class_depictions, :controller => "api/ontology"

  # TODO: review all these for mx3
  # map.namespace  :api, :only => [:index, :show] do |api|
  #  api.resources :figure
  #  api.resources :ontology
  #  api.resources :ref
  # end

  # # handles development non-api calls
  # map.namespace :api, :path_prefix => "/projects/:proj_id/api", :only => [:index, :show] do |api|
  #  api.resources :figure
  #  api.resources :ontology
  #  api.resources :ref
  # end

  # matrix/coding routes
  match "/projects/:proj_id/:controller/fast_code/:id/:mode/:position/:otu_id/:chr_id/:chr_state_id", :action => "fast_code" , :constraints => { :id => /\d+/, :otu_id => /\d+/, :chr_id => /\d+/, :mode => /row|col/} # mode is "row" or "col"
  match "/projects/:proj_id/:controller/fast_code/:id/:mode/:position/:otu_id/:chr_id", :action => "fast_code", :constraints => { :id => /\d+/, :otu_id => /\d+/, :chr_id => /\d+/, :mode => /row|col/}
  match "/projects/:proj_id/:controller/code/:id/:otu_id/:chr_id", :action => "show_code",  :constraints => { :id => /\d+/, :otu_id => /\d+/, :chr_id => /\d+/} # for cell clicks

  # They are meant to only match controllers like 'public/foo', but the constraints seem to do nothing.
  # I don't think we need these (we shouldn't if the conversion from 2.3.10 is possible.
  # Regardless- why don't the constraints work?!?  And neither does the block version (maybe that's only Rails 3.0)

  match "/projects/:proj_id/:controller(/:action(/:id(.:format)))", :controller=> /(public\/)?[^\/]+/
  match "/:controller(/:action(/:id(.:format)))", :controller=> /(public\/)?[^\/]+/


  # TODO: review all these for mx3
  ## associations
  #map.connect "/projects/:proj_id/:controller/:action/association/:association_id/:id",
  #  :requirements => {  :proj_id => /\d+/,
  #                      :id => /\d+/}

  ## content
  # map.connect "/projects/:proj_id/:controller/edit_page/:id/:content_template_id",
  #    :requirements => {:proj_id => /\d+/,
  #                      :id => /\d+/,
  #                      :content_template_id => /\d+/},
  #    :action => "edit_page"

  # map.connect "/projects/:proj_id/:controller/:action/:id/:con_template_id",
  #    :requirements => {:proj_id => /\d+/,
  #                      :id => /\d+/,
  #                      :con_template_id => /\d+/}

  # match "*anything", :to => "application#index", :unresolvable => "true"
end
