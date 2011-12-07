require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'content_types_controller'

# Re-raise errors caught by the controller.
class ContentTypesController; def rescue_action(e) raise e end; end

class ContentTypesControllerTest < ActionController::TestCase

  fixtures :content_types

  def setup
    @controller = ContentTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login
    @opts =  {:controller => "content_types", :proj_id => "1"}
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
     assert_response(:success)
  end
  
  def test_edit
    get :edit, @opts.update(:id => 1)
    assert_response(:success)
  end
  
  def test_destroy
     post :destroy, @opts.update(:id => 1)
     assert_response(302)
  end
 
  def test_add_content_type
    assert_equal 5, ContentType.find(:all).size
    post :create, :content_type => {:name => 'foo', :proj_id => "1"}, :proj_id =>"1"
    assert_equal "Content type was successfully created.", flash[:notice] 
    assert_equal 1, assigns['proj'].id
    
    assert_redirected_to(:action => 'show', :controller => 'content_types', :id => ContentType.find(:all).last.id ) # in fact rails testing won't include proj/1, so we get it partially right
    
    # so I cheat, and rather than use follow_redirect (which won't work because proj/1 is not included) we just reload the index
    opts = { :proj_id => "1"}   
    get :index, opts  
    assert_equal 6, assigns['content_types'].size
    assert_equal 6, assigns['proj'].content_types.count
    assert_template('list')
    assert assigns[:content_types]
    assert_equal 'Proj', assigns['proj'].class.to_s # assigns checks variables that were set in last request
    assert_tag :content => "foo" # hmmm- test works but real life fails
  end
end
