require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'otu_controller'

# Re-raise errors caught by the controller.
class OtuController; def rescue_action(e) raise e end; end

class OtuControllerTest < ActionController::TestCase
  def setup
    @controller = OtuController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login
    @opts =  {:controller => "otu", :proj_id => "1"}
  end

  # just testing loads 
  def test_index
    get :index, @opts
    assert_response(:redirect)
  end

  def test_list
    get :list, @opts
    assert_response(:success)
  end

  def test_list_all
    get :list_all, @opts
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

 # def test_destroy
 #   @opts.update(:id => "1")
 #   get :destroy, @opts
 #   assert_response(:success)
 # end

  def test_show_tags_no_layout
    @opts.update(:id => "1")
    post :show_tags_no_layout, @opts
    assert_response(:success)
  end

  def test_show_summary
    @opts.update(:id => "1")
    get :show_summary, @opts
    assert_response(:success)
  end

   def test_show_kml_text
    @opts.update(:id => "1")
    get :show_kml_text, @opts
    assert_response(:success)
  end

   def test_show_map
    @opts.update(:id => "1")
    get :show_map, @opts
    assert_response(:success)
  end

   def test_show_distribution
    @opts.update(:id => "1")
    get :show_distribution, @opts
    assert_response(:success)
  end

  def test_show_groups
    @opts.update(:id => "1")
    get :show_groups, @opts
    assert_response(:success)
  end
 
  def test_show_material_examined
    @opts.update(:id => "1")
    get :show_material_examined, @opts
    assert_response(:success)
  end
  
  def test_show_content
    @opts.update(:id => "1")
    get :show_content, @opts
    assert_response(302)
  end
 
  def test_show_matrix_sync
    @opts.update(:id => "1")
    get :show_matrix_sync, @opts
    assert_response(:success)
  end
 
  def test_show_compare_content_with_no_existing_content_types
    @opts.update(:id => "1")
    get :show_compare_content, @opts
    assert_response(200) # likely wrong
  end
 
end
