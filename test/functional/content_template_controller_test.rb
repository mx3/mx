require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'content_template_controller'

# Re-raise errors caught by the controller.
class ContentTemplateController; def rescue_action(e) raise e end; end

class ContentTemplateControllerTest < ActionController::TestCase

  fixtures :content_templates, :otus
  self.use_instantiated_fixtures  = true 

  def setup
    @controller = ContentTemplateController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login
    @opts =  {:controller => "content_template", :proj_id => "1"}
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
 
  def test_show_page
     get :show_page, @opts.update(:id => 1, :otu_id => 1, :ct_id => 1)
     assert_response(:success)
  end

end
