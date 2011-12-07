require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'otu_groups_controller'

# Re-raise errors caught by the controller.
class OtuGroupsController; def rescue_action(e) raise e end; end

class OtuGroupsControllerTest < ActionController::TestCase
  fixtures :otu_groups, :otus, :projs, :people

  def setup
    super
    login
    @proj = projs(:projs1)
    @opts =  {:controller => "otu_groups", :proj_id => "1"}
  end

  def teardown
    session = nil
  end

  test "re sorting the OTU groups on the details page" do
    # Add 3 of them
    assert_difference "OtuGroupsOtu.count", 1 do
      post :add_otu, @opts.merge(:id=>1, :otu=>{:id=>otus(:otus1).id})
      assert_redirected_to :action=>:show, :id=>1
    end

    assert_difference "OtuGroupsOtu.count", 1 do
      post :add_otu, @opts.merge(:id=>1, :otu=>{:id=>otus(:otus2).id})
      assert_redirected_to :action=>:show, :id=>1
    end

    assert_difference "OtuGroupsOtu.count", 1 do
      post :add_otu, @opts.merge(:id=>1, :otu=>{:id=>otus(:otus3).id})
      assert_redirected_to :action=>:show, :id=>1
    end

    get :show, @opts.merge(:id=>1)
    assert_response :success
    current_order = @controller.instance_eval{ @otus_in }.map(&:id)
    new_order = current_order.reverse

    # Flip the order
    post :sort_otus, @opts.merge(:id=>1, :otu_groups_otu => new_order)

    get :show, @opts.merge(:id=>1)
    assert_response :success
    assert_equal new_order, @controller.instance_eval{ @otus_in }.map(&:id)

    current_order = new_order
    new_order = new_order.reverse
    # Flip it back
    post :sort_otus, @opts.merge(:id=>1, :otu_groups_otu => new_order)
    get :show, @opts.merge(:id=>1)
    assert_response :success
    assert_equal new_order, @controller.instance_eval{ @otus_in }.map(&:id)

  end

  def test_route_to_index
    opts = {:controller => "otu_groups", :action => "index", :proj_id => "1"}
    assert_recognizes opts , 'projects/1/otu_groups'
    assert_routing "projects/1/otu_groups", opts
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
