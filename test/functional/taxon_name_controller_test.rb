require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'taxon_name_controller'

# Re-raise errors caught by the controller.
class TaxonNameController; def rescue_action(e) raise e end; end

class TaxonNameControllerTest < ActionController::TestCase

  fixtures :taxon_names, :people, :projs, :people_taxon_names # :projs_taxon_names 
  
  def setup
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @controller = TaxonNameController.new
    login
    @opts =  {:controller => "taxon_name", :proj_id => "1"}
  end

  # just testing loads 
  def test_index
    get :list, @opts
    assert_response(:success)
  end

  # we should to add data to projs_taxon_names for this to be legit, right now it works because
  # user 1 can edit at root
  def test_show
    @opts.update(:id => "1" )
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

  def test_rebuild_cached_display_name
    @opts.update(:id => "1")
    get :rebuild_cached_display_name, @opts
    assert_response(302)
  end

  def test_show_type_material
    @opts.update(:id => "1")
    get :show_type_material, @opts
    assert_response(:success)
  end

  def test_show_ITIS_dump
    @opts.update(:id => "1")
    get :show_ITIS_dump, @opts
    assert_response(:success)
  end

  def test_show_images
    @opts.update(:id => "1")
    get :show_images, @opts
    assert_response(:success)
  end
  
  def test_show_immediate_child_otus
    @opts.update(:id => "1")
    get :show_immediate_child_otus, @opts
    assert_response(:success)
  end

  def test_show_all_children
    @opts.update(:id => "1")
    get :show_all_children, @opts
    assert_response(:success)
  end

  def test_show_taxonomic_history
    @opts.update(:id => "1")
    get :show_taxonomic_history, @opts
    assert_response(:success)
  end

  def test_show_tags
    @opts.update(:id => "1")
    get :show_tags, @opts
    assert_response(:success)
  end




end
