# encoding: utf-8
require_dependency "person"

# here is the cascade of possibilities:
# 1) controllers that don't call 'before_filter :login_required' have no authentication whatsoever.
# 2) controllers that do require login can have actions that aren't protected. (how are these identified)?
# 3) some controllers do not require a project to be selected, but do require login
# 4) all other controllers require a project, a user, and for the user to be a member of that project

# 5) some controllers require the user to be an administrator

## 6) some evironments don't require logins (test) ???? likely a bad idea

module LoginSystem

  protected

  # overwrite this if you want to restrict access to only a few actions
  # or if you want to check if the person has the correct rights
  def authorize?(person)
    true
  end

   # overwrite this method to un-protect certain actions of the controller
   def protect?(action)
     true
   end

   # login_required filter. added to all controllers (through application.rb), so everything requires
   # login by default. override the relevant methods in the individual controllers to free things up.
   # The only time fals is returned is if the session[:person] is not previously set. 
   def login_required

    $person_id = nil

    if not protect?(action_name) # action_name comes from routing
      return true
    end

    if session[:person] && authorize?(session[:person])
      # this allows all models to record who makes changes
      # (in conjunction with the standard field manager mixin stuff)
      # i know globals are bad, but don't see another way to make
      # the user_id available to all models automatically
      $person_id = session[:person].id
      return true
    end

    # store current location so that we can come back after the person logged in
    store_location

    # call overwriteable reaction to unauthorized access
    access_denied
    return false
  end

  # Reload the project every time- we might be able to cache/not do so ultimately
  # TODO: can we mem-cache this?
  def load_proj(id)
    proj = Proj.find(id, :include => :people)

    if proj.people.include? session[:person]
        session[:proj] = proj
      return true
    else
      return false
    end
  end

  # check if we are 'in' a project, and if so, if the user is a member of that project
  def proj_required

    session[:proj] = nil unless params[:proj_id]

    # TODO: this is borked somewhat re hitting the /projs/ controller. 
    # exceptions: you do not need to have selected a project to use these controllers
    if ['account', 'admin',  'namespaces','image_views'].include?(controller_name)
      return true
    end

    # There is presently no option for allowed or not (e.g. news), but see mod to check_proj in standard fields

    # the tn autocomplete is needed by the admin controller
    if ('taxon_names' == controller_name) && ('auto_complete_for_taxon_names' == action_name)
      return true unless params["proj_id"] # nasty: if we are in a project, we will need the @proj variable
    end

    # ditto for news
    if 'news' == controller_name
      return true unless params["proj_id"] # nasty: if we are in a project, we will need the @proj variable
    end

    # or these methods of of the proj controller
    if controller_name == 'projs' # REMOVED WITH NEW CONTROLLERS && ['index','new', 'create', 'list'].include?(action_name)
      return true
    end

    # the proj_id comes from routing
    if params[:proj_id]
      if load_proj(params[:proj_id]) # only succeeds if person is a member
        @proj = session[:proj]
        $proj_id = @proj.id
        return true
      end
    end

    # if you got to here you're in big trouble, and we're sending you back to choose a proj
    redirect_to :controller => '/projs', :action => :list # "/proj", :action =>"list"
    return false
  end

  # overwrite if you want to have special behavior in case the person is not authorized
  # to access the current operation.
  # the default action is to redirect to the login screen
  def access_denied
    redirect_to :controller => :account, :action => :login # "/account", :action =>"login"
  end

  # store current uri in the session.
  # we can return to this location by calling return_location
  def store_location
    # modified for oddness, perhaps new routing in 2.0
    session['return-to'] = request.parameters # (request.request_uri == '/' ? nil : request.request.request_uri)
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session['return-to'].blank?
      redirect_to(default) and return
    else
      redirect_to(session['return-to'])
      session['return-to'] = nil
    end
  end

end
