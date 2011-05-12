require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


require 'proj_controller'

# Re-raise errors caught by the controller.
class ProjController; def rescue_action(e) raise e end; end

class ProjControllerTest < ActionController::TestCase
  def setup
    @controller = ProjController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login
  end

  def test_index
    opts = {:controller => "proj", :action => "index", :proj_id => "1"}
    assert_recognizes opts , 'projects/1'
    assert_routing "projects/1", opts   
    
    get :list, opts
    assert_response(:success)
  end

  # these routes need cleaning to remove redundant ID
  def test_show
    opts = {:controller => "proj", :action => "show", :proj_id => "1", :id => "1"}
  # assert_recognizes opts , 'projects/show/1'
  # assert_routing "projects/show/1", opts   
    
    get :show, opts
    assert_response(:success)
  end

  def test_edit
    opts = {:controller => "proj", :action => "edit", :proj_id => "1", :id => "1"}
    assert_recognizes opts , 'projects/1/proj/edit/1'
    assert_routing "projects/1/proj/edit/1", opts   
    
    get :edit, opts
    assert_response(:success)
  end

end
