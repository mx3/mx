require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'seq_controller'

# Re-raise errors caught by the controller.
class SeqController; def rescue_action(e) raise e end; end

class SeqControllerTest < ActionController::TestCase
 fixtures :seqs, :otu_groups, :genes
  
  def setup
    @controller = SeqController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login
    @opts =  {:controller => "mx", :proj_id => "1"}
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

  def test_create_multiple
    @opts.update(:multi_seq => {:gene_id => 1, :otu_group_id => 1})
    get :create_multiple, @opts
    assert_response(302)
  end

   def test_seqs_from_FASTA
    get :seqs_from_FASTA, @opts
    assert_response(:success)
  end

end
