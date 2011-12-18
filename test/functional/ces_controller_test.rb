require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'ces_controller'

# Re-raise errors caught by the controller.
class CesController; def rescue_action(e) raise e end; end

class CesControllerTest < ActionController::TestCase

  def setup

    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @controller = CesController.new
    login
    $person_id = 1
    $proj_id = 1
    @ce = Ce.create!
    @opts =  {:controller => "ces", :proj_id => "1"}
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

  %w(collectors locality mthd verbatim_method macro_habitat micro_habitat).each do |field|
    test "autocompleter for ces on #{field}" do
      ces = [ Ce.make!(:proj => @proj, field => 'foo'),
              Ce.make!(:proj => @proj, field => 'foobar'),
              Ce.make!(:proj => @proj, field => 'bar')
            ]
      get :auto_complete_for_ces, :proj_id => @proj.id, :field => field
      assert_response :bad_request

      get :auto_complete_for_ces, :proj_id => @proj.id, :field => field, :term=>'foo'
      assert_response :success
      assert_equal 2, ActiveSupport::JSON.decode(@response.body).size

      get :auto_complete_for_ces, :proj_id => @proj.id, :field => field, :term=>'bar'
      assert_response :success
      assert_equal 2, ActiveSupport::JSON.decode(@response.body).size

      get :auto_complete_for_ces, :proj_id => @proj.id, :field => field, :term=>'foobar'
      assert_response :success
      assert_equal 1, ActiveSupport::JSON.decode(@response.body).size
    end
  end
end
