require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'ce_controller'

# Re-raise errors caught by the controller.
class CeController; def rescue_action(e) raise e end; end

class CeControllerTest < ActionController::TestCase

  def setup

    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @controller = CeController.new
    login
    $person_id = 1
    $proj_id = 1
    @ce = Ce.create!
    @opts =  {:controller => "ce", :proj_id => "1"}
  end

  # just testing loads 
  def test_index
    get :list, @opts
    assert_response(:success)
  end

  def test_show
    @opts.update(:id => @ce.id.to_s)
    get :show, @opts
    assert_response(:success)
  end

  def test_edit
    @opts.update(:id => @ce.id.to_s)
    get :edit, @opts
    assert_response(:success)
  end

  def test_new
    get :new, @opts
    assert_response(:success)
  end

  def test_destroy
    @opts.update(:id => @ce.id)
    post :destroy, @opts
    assert_response(:redirect)
  end

end
