require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'refs_controller'

# Re-raise errors caught by the controller.
class RefsController; def rescue_action(e) raise e end; end

class RefsControllerTest < ActionController::TestCase
  fixtures :refs

  def setup
    @controller = RefsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login
    @opts =  {:controller => 'refs', :proj_id => "1"}
  end

  def test_index
    get :index, @opts
    assert_response(:success)
    
    # below doesn't work because of :only_path => true weirdness
    # @opts.update(:action => 'index')
    # assert_recognizes @opts.update(:only_path => true), 'projects/1/ref'
    # assert_routing "projects/1/ref", @opts   
  end

  def test_list
    get :list, @opts
    assert_response(:success)
  end

  def test_show
    get :show, @opts.update(:id => 1)
    assert_response(:success)
  end

  def test_new
    get :new, @opts
    assert_response(:success)
  end
  
  def test_create
    get :create, @opts
    assert_response(302)
  end
  
  def test_edit
    get :edit, @opts.update(:id => 1)
    assert_response(:success)
  end
  
  def test_destroy
    get :destroy, @opts.update(:id => 1)
    assert_response(302)
  end
  
  def test_list_by_author_name
    get :list_by_author, @opts.update(:name => 'foo')
    assert_response(:success)
  end
  
  def test_list_by_author_letter
    get :list_by_author, @opts.update(:letter => 'f')
    assert_response(:success)
  end
  
  def test_show_sensus
    get :show_sensus, @opts.update(:id => 1)
    assert_response(:success)
  end
  
  def test_link_search
    get :link_search, @opts.update(:id => 1)
    assert_response(:success)
  end
  
  def test_show_tags
    get :show_tags, @opts.update(:id => 1)
    assert_response(:success)
  end

  def test_show_associations
    get :show_associations, @opts.update(:id => 1)
    assert_response(:success)
  end

  def test_show_distributions
    get :show_distributions, @opts.update(:id => 1)
    assert_response(:success)
  end
  
  def test_endnote
    get :endnote, @opts
    assert_response(:success)
  end

end
