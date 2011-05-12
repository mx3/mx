require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


require 'otu_group_controller'

# Re-raise errors caught by the controller.
class OtuGroupController; def rescue_action(e) raise e end; end

class OtuGroupControllerTest < ActionController::TestCase
  fixtures :otu_groups 

  def setup
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @controller = OtuGroupController.new
    login
    @opts =  {:controller => "otu_group", :proj_id => "1"}
  end

  def teardown
    session = nil
  end
  
  def test_route_to_index
    opts = {:controller => "otu_group", :action => "index", :proj_id => "1"}
    assert_recognizes opts , 'projects/1/otu_group'
    assert_routing "projects/1/otu_group", opts   
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

  def test_show_material
    @opts.update(:id => "1")
    get :show_material, @opts    
    assert_response(:success)
  end

  def test_show_images
    @opts.update(:id => "1")
    get :show_images, @opts    
    assert_response(:success)
  end
  
  def test_show_content_grid
    @opts.update(:id => "1")
    get :show_content_grid, @opts    
    assert_response(:success)
  end

  def test_show_extract_grid
    @opts.update(:id => "1")
    get :show_content_grid, @opts    
    assert_response(:success)
  end

end
