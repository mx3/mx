require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require File.expand_path(File.dirname(__FILE__) + "/../../config/routes.rb")

class RoutingTest < ActionController::TestCase

  # Recognizes

  def test_recognizes_base_route
    assert_recognizes({"controller" => "proj", "action" => "index"}, "/")
  end

  def test_recognizes_basic_private_pattern
    assert_recognizes({"controller" => "otu", "action" => "new", "proj_id" => "1"}, "/projects/1/otu/new")
  end 

  def test_recognizes_basic_private_pattern_with_id
    assert_recognizes({"controller" => "otu", "action" => "show", "proj_id" => "1", "id" => "1"}, "/projects/1/otu/show/1")
  end 

  def test_recognizes_basic_private_pattern_with_id_and_format
    assert_recognizes({"controller" => "otu", "action" => "show", "proj_id" => "1", "id" => "1", "format" => "json"}, "/projects/1/otu/show/1.json")
  end 

  def test_recognizes_basic_private_pattern_with_no_project_for_admin
    assert_recognizes({"controller" => "admin", "action" => "new_proj"}, "/admin/new_proj")
  end 

  # TODO: (later) Should reformulate to hit CodingController CRUD, then redirect 
  def test_recognizes_matrix_code_specific
    assert_recognizes({"controller" => "mx", "action" => "show_code", "proj_id" => "1", "otu_id" => "1", "chr_id" => "1", "id" => "1"}, "/projects/1/mx/code/1/1/1") 
    assert_recognizes({"controller" => "mx", "action" => "fast_code", "position" => "1", "chr_state_id" => "1", "mode" => "row", "proj_id" => "1", "otu_id" => "1", "chr_id" => "1", "id" => "1"}, "/projects/1/mx/fast_code/1/row/1/1/1/1") 
  end 

  def test_recognizes_api_specific
    assert_recognizes({"controller" => "api/ontology", "action" => "obo_file", "proj_id" => "1"}, "/projects/1/api/ontology/obo_file") 
    assert_recognizes({"controller" => "api/ontology", "action" => "obo_file"}, "/api/ontology/obo_file")
  end 

  def test_recognizes_basic_public_pattern
    assert_recognizes({"controller" => "public/otu", "action" => "show", "proj_id" => "1", :id => "1"}, "/projects/1/public/otu/show/1")
    assert_recognizes({"controller" => "public/otu",  "action" => 'index', "proj_id" => "1"}, "/projects/1/public/otu")
  end 

  # Generate

  def test_generates_default_basic_private_pattern
    assert_generates("/projects/1/otu/new", controller: "otu", action: "new", proj_id: "1")
  end 

  def test_generates_default_basic_public_pattern
    assert_generates("/projects/1/public/otu", controller: "public/otu", proj_id: "1", action: 'index')
  end 

  def test_generates_default_basic_public_pattern_with_id
    assert_generates("/projects/1/public/otu/show/1", controller: "public/otu", action: "show", proj_id: "1", id: "1")
  end 


  # Routing
  
  # Redundant, just another version. 
  def test_routing
    assert_routing("/projects/1/otu/show/1", proj_id: "1", controller: "otu", action: "show", id: "1")
  end 
   
end
