require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

# Re-raise errors caught by the controller.
class ProjsController; def rescue_action(e) raise e end; end

class ProjsControllerTest < ActionController::TestCase
  def setup
    @controller = ProjsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login
  end

  def test_index
    opts = {:controller => "projs", :action => "index"}
    get :index, opts
    assert_response(:success)
  end

  # these routes need cleaning to remove redundant ID
  def test_show
    opts = {:controller => "projs", :action => "show", :id => "1"}
    assert_routing 'projs/1', opts
    get :show, opts
    assert_response(:success)
  end

  def test_edit
    opts = {:controller => "projs", :action => "edit",  :id => "1"}
    assert_generates 'projs/1/edit', opts
    assert_recognizes opts, 'projs/1/edit'
    get :edit, opts
    assert_response(:success)
  end

end
