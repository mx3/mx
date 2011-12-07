require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'ontology_controller'

# Re-raise errors caught by the controller.
class OntologyController; def rescue_action(e) raise e end; end

class OntologyControllerTest < ActionController::TestCase
  def setup
    @controller = OntologyController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    login
    @opts =  {:controller => "ontology", :proj_id => "1"}
  end

  # just testing loads 
  def test_index
    get :index, @opts
    assert_response(:success)
  end


end
