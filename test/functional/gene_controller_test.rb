require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


require 'gene_controller' 

# Re-raise errors caught by the controller.
class GeneController; def rescue_action(e) raise e end; end

class GeneControllerTest < ActionController::TestCase
  fixtures :genes
  
  def setup
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @controller = GeneController.new
    login
  end
 
  def teardown
    session = nil
  end
  
  def test_login
    assert_equal "test", @p.login
  end
  
  def test_route_to_index
    opts = {:controller => "gene", :action => "index", :proj_id => "1"}
    assert_recognizes opts , 'projects/1/gene'
    assert_routing "projects/1/gene", opts
  end

  def test_route_to_new
    opts = {:controller => "gene", :action => "new", :proj_id => "1"}
    assert_routing "projects/1/gene/new", opts
  end
   
  def test_index  
    #  post :login, "person_login" => "test", "person_password" => "test01"
    opts = { :proj_id => "1" } 
    
    get :index, opts
    assert(@response.has_session_object?(:proj))

    assert_equal 3, assigns(:genes).size
  end 
    
  # should be an integration test
  def test_add_gene
    assert_equal 3, @genes.size # test the fixture
    post :create, :gene => {:name => 'new_gene_ZYYZ'}, :proj_id =>"1"
    assert_equal "Gene was successfully created.", flash[:notice] 
    assert_equal 1, assigns['proj'].id
    
    # follow_redirect # doesn't work, tries /gene/list not projects/1/genes/list 
    assert_redirected_to(:action => 'list', :controller => 'gene') # in fact rails testing won't include proj/1, so we get it partially right
    
    # so I cheat, and rather than use follow_redirect (which won't work because proj/1 is not included) we just reload the index
    opts = { :proj_id => "1"}   
    get :index, opts  
    assert_equal 4, assigns['genes'].size # tests that @genes is being set
    assert_equal 4, assigns['proj'].genes.count
    assert_template('list')
    assert(@response.has_template_object?('genes'))
    assert_equal 'Proj', assigns['proj'].class.to_s # assigns checks variables that were set in last request

    assert_tag :content => "new_gene_ZYYZ"
  end
  
  
end
