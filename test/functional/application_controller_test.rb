require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'application_controller'

class ApplicationController; def rescue_action(e) raise e end; end 
class ApplicationControllerTest < ActionController::TestCase

  # include ActionDispatch::Routing::UrlFor

  def setup
    @controller = AccountController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
  end

  def teardown
    session = nil
  end

  # Need to test the setting of @proj, $person_id, $proj_id here

end
