require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'lot_controller'

# Re-raise errors caught by the controller.
class LotController; def rescue_action(e) raise e end; end

class LotControllerTest < ActionController::TestCase

   fixtures :lots, :otus

  self.use_instantiated_fixtures  = true 
  
  def setup
    @controller = LotController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login
    @opts =  {:controller => "lot", :proj_id => "1"}
  end

  def teardown
    session = nil
  end

  # just testing loads 
  def test_index
    get :list, @opts
    assert_response(:success)
  end

  def test_show
    @opts.update(:id => "1")
    get :show, @opts
    assert_response(:success)
  end

  def test_edit
    @opts.update(:id => "1")
    get :edit, @opts
    assert_response(:success)
  end

  def test_new
    get :new, @opts
    assert_response(:success)
  end


end
