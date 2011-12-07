require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'chr_groups_controller'

# Re-raise errors caught by the controller.
class ChrGroupsController; def rescue_action(e) raise e end; end

class ChrGroupsControllerTest < ActionController::TestCase
  fixtures :chr_groups 

  def setup
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @controller = ChrGroupsController.new
    login
    @opts =  {:controller => "chr_groups", :proj_id => "1"}
  end

  def teardown
    session = nil
  end

  def test_login
    assert_equal "test", @p.login
  end

  def test_route_to_index
    opts = {:controller => "chr_groups", :action => "index", :proj_id => "1"}
    assert_recognizes opts , 'projects/1/chr_groups'
    assert_routing "projects/1/chr_groups", opts   
  end

  # just testing loads 
  def test_index
    get :index, @opts
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

  def test_show_detailed
    @opts.update(:id => '1')
    get :show_detailed, @opts
    assert_response(:success)
  end

  def test_show_content_mapping
    @opts.update(:id => '1')
    get :show_content_mapping, @opts
    assert_response(:success)
  end

end
