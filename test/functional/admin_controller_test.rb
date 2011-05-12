require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < ActionController::TestCase
  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login # user 1 is an admin, this sets @proj, and $person_id
  end

  # just tests to see that the pages can be loaded

  def test_index 
    opts = {:controller => "admin"}
    get :index, opts
    assert_response(:success)
  end

  def test_stats
    opts = {:controller => "admin"}
    get :stats, opts
    assert_response(:success)
  end

  def test_people_tn
    opts = {:controller => "admin", :id => "1"} # id is a person_id
    get :people_tn, opts
    assert_response(:success)
  end

  def test_reset_password
    opts = {:controller => "admin"}
    get :reset_password, opts
    assert_response(:success)
  end

  def test_new_proj
    opts = {:controller => "admin"}
    get :new_proj, opts
    assert_response(:success)
  end

end
