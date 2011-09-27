require_dependency "login_system"

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
 # include ExceptionNotification::Notifiable

  protect_from_forgery

  # TODO: move?
  class ApplicationController::BatchParseError < StandardError
  end

  # Include these helpers all the time
  helper 'app/layout', 'app/layout' , 'app/display', 'app/navigation',  :javascript, :otu, :seq, :specimen, :taxon_name, :figure, :image, :confidence,  :ref, :sensu, :content, :geog, :ontology_relationship, :ontology_class, :tag, :image_description, :public_content, :extracts_gene, :label, :ontology, :phenotype, :ce, :namespace

  include LoginSystem

  before_filter :configure_site # forks to a public or private mode, calling the authentications if private
  around_filter :ffx_xhr_redirect_hack
  after_filter  :add_flash_to_json_header
#  before_filter :set_charset
  layout :layout_for_xhr

  [:notice, :warning, :error].each do |type|
    define_method(type) do |msg|
      if flash[type].is_a? String
        flash[type] = [flash[type]]
      else
        flash[type] ||= []
      end
      flash[type] << msg
    end
    define_method("clear_#{type}")do
      flash[type] = []
    end
    define_method("#{type}_now") do |msg|
      if flash.now[type].is_a? String
        flash.now[type] = [flash.now[type]]
      else
        flash.now[type] ||= []
      end
      flash.now[type] << msg
    end
  end

  # built in Rails-ness
  def method_missing(methodname, *args)
    @methodname = methodname
    @args = args
    public_route_failure and return
  end

  protected

  # UGH. FFX Bug: https://bugzilla.mozilla.org/show_bug.cgi?id=553888
  # If you redirect an XHR request, it will not be redirected as an XHR request, but
  # as a plain old request.
  # To fix this -- we stuff some things into the reqdirected query string
  # and catch it next time we have a request.
  REDIRECTED_XHR_REQUEST_KEY = "_rxr"
  def ffx_xhr_redirect_hack
    # If this param is on the request, it's from a redirected XHR request.
    # Force this request to XHR.
    if (params[REDIRECTED_XHR_REQUEST_KEY])
      self.request.env['HTTP_X_REQUESTED_WITH'] = "XMLHttpRequest-#{REDIRECTED_XHR_REQUEST_KEY}"
    end

    yield

    if (self.request.xhr? && !self.response['Location'].blank?)
      url = self.response.location
      self.response.location = url + (url.include?('?') ? '&' : '?') + "#{REDIRECTED_XHR_REQUEST_KEY}=1"
    end
  end

  def add_flash_to_json_header
    # If we are XHR and redirecting - don't show the flash just yet
    if request.xhr? && response.location.blank?
      last_flash = ActiveSupport::JSON.decode(session[:redirected_xhr_flash]) rescue {}
      this_flash = flash.to_hash
      returned_flash = last_flash.merge(this_flash)

      response.headers['X-JSON'] = returned_flash.to_json

      #update last-modified so content is always fresh
      headers['Last-Modified'] = Time.now.httpdate
      session.delete(:redirected_xhr_flash)
      flash.discard
    elsif request.xhr?
      # We save this off until next time -
      session[:redirected_xhr_flash] = flash.to_json
      flash.discard
    else
      session.delete(:redirected_xhr_flash)
    end
  end

  def layout_for_xhr
    if (request.xhr?)
      'xhr'
    else
      'application'
    end
  end

  def public_route_failure
    render(:file => "#{Rails.root}/public/404.html", :status => "404 Not Found")
  end

  # def set_charset
  #  headers["Content-Type"] = "text/html; charset=utf-8"
  # end

  # aside from this logic here, a site has:
  # - settings in the project table
  # - a layout
  # - style sheets, images, etc
  # - controllers/views (or it can share)
  #
  # The following variables are set on every call:
  # @public         - determines whether login is required and used as a check in various method calls
  # @server_name    - primarily used as a conditional for ease of working in different RAILS_ENV (development, test, production)

  # HOME_SERVER is defined in config/initializers/local_config.rb
  # login_required and proj_required are defined in lib/login_system

  def configure_site

    if params[:unresolvable] # called when bad queries are thrown at the db (i.e routed from *anything)
      public_route_failure and return
    end

    # TODO: just make this test for RAILS_ENV=development?
    # recognizes both http://www.foo.org and http://foo.org
    if ["0.0.0.0", "127.0.0.1"].include?(self.request.remote_addr)
      @server_name = 'development'
    else
      @server_name = self.request.server_name.sub(/^www\./, "")
    end


    if (@server_name == HOME_SERVER || @server_name == 'development') && (self.class.controller_path[0,7] != "public/")
      # Hitting the "private" application interface
      if login_required
        proj_required    # ** Sets @proj when login is required.
      end
      @public = false

    else
      # Hitting the public application interface, login not required
      @public = true

      # For requests like "http://foo.bar.com/ with no controller redirect to the appropriate home_controller
      if self.controller_name == "proj"
        unix_name = Proj.return_by_public_server_name(@server_name).unix_name
        redirect_to :action => 'index', :controller => "public/site/#{unix_name}/home" and return
      end

      # At this point we're looking for the specific project
      # The logic:
      # 1) Use the id if provided '/projects/id/foo'
      # 2) If /projects is not provided (e.g. public or other calls) use the unix name to find the project
      # 3) We're in development (testing), here @server_name == 'testing' and no project should be found
      if params[:proj_id]
        @proj = Proj.find(params[:proj_id])
      else # find the project by server name
        @proj ||= Proj.return_by_public_server_name(@server_name)
      end

      # If project not found, or class == public, or it's not public controller return a 404
      # If its a home controller then it's OK.
      is_home_controller = (self.controller_name == "home")
      is_allowed_public_controller = (@proj && self.class.controller_path[0,7] == "public/" && @proj.public_controllers.include?(self.controller_name))
      is_api_controller =  (self.class.controller_path[0,3] == 'api')

      if (!is_allowed_public_controller && !is_home_controller && !is_api_controller)
         public_route_failure and return
      end

      # Request is for a non-existant controller
      if (!@proj)
         public_route_failure and return
      end

      $proj_id = @proj.id # for non-public pages this gets set in # proj_required
    end

    true # Return true or Rails' filter chain halts
  end


end
