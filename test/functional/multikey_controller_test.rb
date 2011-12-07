require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'multikey_controller' 

# Re-raise errors caught by the controller.
class MultikeyController; def rescue_action(e) raise e end; end

class MultikeyControllerTest < ActionController::TestCase
  
  fixtures :mxes
  fixtures :chrs_mxes
  fixtures :chrs
  fixtures :chr_states
  fixtures :mxes_otus
  fixtures :otus
  fixtures :codings
  fixtures :chr_groups
  fixtures :chr_groups_chrs

#  self.use_instantiated_fixtures  = true

  def setup
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    login
    @controller = MultikeyController.new
  end

  def teardown
    session = nil
  end

  def test_login
    assert_equal "test", @p.login
  end

  def test_route_to_index
    opts = {:controller => "multikey", :action => 'index', :proj_id => "1"}
    assert_recognizes opts , 'projects/1/multikey'
    assert_routing "projects/1/multikey", opts   
  end

  # not even close to working as test
  def test_remove_state
    opts = { :proj_id => "1",  'id' => "4" } # 4 is the multikey YAML data 
    get :show, opts
    assert_template('show')
    #    assert_rendered_file 'show'
    # assert_equal 0, @chrs_elim.size # test the fixture
    #post :create, :gene => {:name => 'new_gene_ZYYZ'}, :proj_id =>"1"

    #  assert_equal "Gene was successfully created.", flash[:notice] 
    #assert_equal 1, assigns['proj'].id

    # follow_redirect # doesn't work, tries /gene/list not projects/1/genes/list 
    #assert_redirected_to(:action => 'show', :controller => 'multikey') # in fact rails testing won't include proj/1, so we get it partially right

    # so I cheat, and rather than use follow_redirect (which won't work because proj/1 is not included) we just reload the index
    
    ##  get :index, opts  
    ##  assert_equal 4, assigns['genes'].size # tests that @genes is being set
    #  assert_equal 4, assigns['proj'].genes.count
    #  assert_rendered_file 'list'
    #  assert_template_has 'genes'
    #  assert_equal 'Proj', assigns['proj'].class.to_s # assigns checks variables that were set in last request

    # assert_tag :content => "new_gene_ZYYZ"
  end


end
