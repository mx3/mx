require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'chr_controller'

# Re-raise errors caught by the controller.
class ChrController; def rescue_action(e) raise e end; end

class ChrControllerTest < ActionController::TestCase
  fixtures :chrs, :chr_states

  def setup
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @controller = ChrController.new
    login
    @opts = {:controller => "chr", :proj_id => "1"}
  end

  def teardown
    session = nil
  end
  
  def test_login
   assert_equal "test", @p.login
  end
  
  def test_route_to_index
    opts = {:controller => "chr", :action => "index", :proj_id => "1"}
    assert_recognizes opts , 'projects/1/chr'
    assert_routing "projects/1/chr", opts   
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

  def test_show_otus_for_state
    @opts.update(:id => "1")
    get :show_otus_for_state, @opts
    assert_response(:success)
  end

  def test_show_groups
    @opts.update(:id => "1")
    get :show_groups, @opts
    assert_response(:success)
  end

 def test_show_mxes
    @opts.update(:id => "1")
    get :show_mxes, @opts
    assert_response(:success)
  end

  def test_show_edit_expanded
    @opts.update(:id => "1")
    get :show_edit_expanded, @opts
    assert_response(:success)
  end

 def test_show_coded_otus
    @opts.update(:id => "1")
    get :show_coded_otus, @opts
    assert_response(:success)
  end

  def test_show_merge_states
    @opts.update(:id => "1")
    get :show_merge_states, @opts
    assert_response(:success)
  end

  def test_list_by_char_group
    get :list_by_char_group, @opts
    assert_response(:success)
  end

  def test_list_recent_changes_by_chr_state
    get :list_recent_changes_by_chr_state, @opts
    assert_response(:success)
  end

  def test_recent_changes_by_chr
    get :list_recent_changes_by_chr, @opts
    assert_response(:success)
  end

  def test_list_all
    get :list_all, @opts
    assert_response(:success)
  end


end
