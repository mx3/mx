require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'mxes_controller'

# Re-raise errors caught by the controller.
class MxesController; def rescue_action(e) raise e end; end

class MxesControllerTest < ActionController::TestCase
  def setup
    @controller = MxesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login
    @opts =  {:controller => "mxes", :proj_id => "1"}
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

  def test_list
    get :list, @opts
    assert_response(:success)
  end

  def test_browse
    @opts.update(:id => "1")
    get :browse, @opts
    assert_response(:success)
  end

  def test_show_otus
    @opts.update(:id => "1")
    get :show_otus, @opts
    assert_response(:success)
  end

  def test_show_characters
    @opts.update(:id => "1")
    get :show_characters, @opts
    assert_response(:success)
  end

  def test_show_sort_characters
    @opts.update(:id => "1")
    get :show_sort_characters, @opts
    assert_response(:success)
  end

  def test_show_sort_otus
    @opts.update(:id => "1")
    get :show_sort_otus, @opts
    assert_response(:success)
  end

  def test_show_trees
    @opts.update(:id => "1")
    get :show_trees, @opts
    assert_response(:success)
  end

  def test_show_tnt
    @opts.update(:id => "1")
    get :show_tnt, @opts
    assert_response(:success)
  end

  def test_show_nexus
    @opts.update(:id => "1")
    get :show_nexus, @opts
    assert_response(:success)
  end

  def test_fast_coding_route_in_nav_without_coding
    opts = {:controller => "mxes", :id => "1", :action => "fast_code", :proj_id => "1", :otu_id => "1", :chr_id => "2", :mode => "row", :position => "5" }
    assert_recognizes opts , 'projects/1/mxes/1/fast_code/row/5/1/2'
    assert_routing 'projects/1/mxes/1/fast_code/row/5/1/2', opts
  end

  def test_fast_coding_route_coding
    opts = {:controller => "mxes", :id => "1", :action => "fast_code", :proj_id => "1",
      :otu_id => "1", :chr_id => "2", :mode => "row", :chr_state_id => '2', :position => "5" }
      assert_recognizes opts , 'projects/1/mxes/1/fast_code/row/5/1/2/2'
      assert_routing           'projects/1/mxes/1/fast_code/row/5/1/2', opts
  end

  def test_fast_coding_route_coding2
      opts = {
        :proj_id        => "1",
        :controller     => "mxes",
        :id             => "1",
        :action         => "fast_code",
        :mode           => "row",
        :position       => "5",
        :otu_id         => "1",
        :chr_id         => "2",
        :chr_state_id   => "2" }
        assert_routing           'projects/1/mxes/1/fast_code/row/5/1/2/2', opts
  end

end
