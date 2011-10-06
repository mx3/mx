require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


require 'otu_group_controller'

# Re-raise errors caught by the controller.
class OtuGroupController; def rescue_action(e) raise e end; end

class OtuGroupControllerTest < ActionController::TestCase
  fixtures :otu_groups, :otus

  def setup
    super
    login
    @opts =  {:controller => "otu_group", :proj_id => "1"}
  end

  def teardown
    session = nil
  end

  test "re sorting the OTU groups on the details page" do
    # Add 3 of them
    assert_difference "OtuGroupsOtu.count", 1 do
      debugger
      otu = otus(:otus1)
      post :add_otu, @opts.merge(:id=>1, :otu=>{:id=>otu.id})
      puts @response.body
      assert_response :success
    end

    assert_difference "OtuGroupsOtu.count", 1 do
      post :add_otu, @opts.merge(:id=>1, :otu=>{:id=>otus(:otus2).id})
    end

    assert_difference "OtuGroupsOtu.count", 1 do
      post :add_otu, @opts.merge(:id=>1, :otu=>{:id=>otus(:otus3).id})
    end

    post :sort_otus, @opts.merge(:id=>1, :otu_groups_otu => [1,2,3])
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
