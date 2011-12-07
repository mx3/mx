require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class SpecimensController; def rescue_action(e) raise e end; end

class SpecimensControllerTest < ActionController::TestCase

  def setup
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @controller = SpecimensController.new
    login
    $person_id = 1
    $proj_id = 1
    @specimen = Specimen.create!
    @opts =  {:controller => :specimens, :proj_id => "1"}
  end

  def test_index
    get :list, @opts
    assert_response(:success)
  end

  def test_show
    @opts.update(:id => @specimen.id.to_s)
    get :show, @opts
    assert_response(:success)
  end

  def test_edit
    @opts.update(:id => @specimen.id.to_s)
    get :edit, @opts
    assert_response(:success)
  end

  def test_new
    get :new, @opts
    assert_response(:success)
  end

  def test_destroy
    @opts.update(:id => @specimen.id)
    post :destroy, @opts
    assert_response(:redirect)
  end

end
