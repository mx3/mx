require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require File.expand_path(File.dirname(__FILE__) + "/../../config/routes.rb")

class RoutingTest < ActionController::TestCase

  # Recognizes
  {
    {:controller => 'project',   :action => 'index' } =>
    '/',

    {:controller => 'otu',    :action => 'new',       :project_id => '1'} =>
    "/project/1/otu/new",

    {:controller => 'otu',    :action => 'show',      :project_id => '1', :id => "1"} =>
    "/project/1/otu/1",

    {:controller => 'otu',    :action => 'show',      :project_id => '1', :id => "1", :format => "json"} =>
    "/project/1/otu/1.json",

    {:controller => 'otu',    :action => 'foo',      :project_id => '1', :id => "1", :format => "json"} =>
    "/project/1/otu/1/foo.json",

    {:controller => 'admin',  :action => 'new_project'} =>
    "/admin/new_project",

    # TODO: (later) Should reformulate to hit CodingController CRUD, then redirect
    {:controller => "mx",     :action => 'show_code', :project_id => "1", :otu_id => "1", :chr_id => "1", :id => "1"} =>
    "/project/1/mx/code/1/1/1",

    {:controller => "mx",     :action => 'fast_code', :project_id => "1", :position => "1", :chr_state_id => "1", :mode => "row", :otu_id => "1", :chr_id => "1", :id => "1"} =>
    "/project/1/mx/fast_code/1/row/1/1/1/1",

    {:controller => "api/ontology", :action => "obo_file", :project_id => "1"} =>
    "/project/1/api/ontology/obo_file",

    {:controller => "api/ontology", :action => "obo_file"} =>
    "/api/ontology/obo_file",

  }.each_pair do |from, to|
    test "#{from.to_json} recognized as #{to.to_json}" do
      assert_recognizes from, to
    end
  end

  # Generates
  {
    "/project/1/otu/new" =>
    {controller: "otu", action: "new", project_id: "1"},

    "/project/1/public/otu" =>
    {controller: "public/otu", project_id: "1"},

    "/project/1/public/otu/1" =>
    {:project_id=>"1", :controller=>"public/otu", :action=>"show", :id=>"1"}
   # {controller: "public/otu", action: "show", project_id: "1", id: "1"}
  }.each_pair do |from, to|
    test "#{from.to_json} recognized as #{to.to_json}" do
      assert_generates from, to
    end
  end

  # Routing
  {
    "/project/1/public/otu/show/1" =>
    {:controller => "public/otu", :action => 'show', :project_id => "1", :id => "1"},

    "/project/1/public/otu" =>
    {:controller => "public/otu", :action => 'index',:project_id => "1"},

    "/project/1/otu/show/1" =>
    { project_id: "1", controller: "otu", action: "show", id: "1"}
  }.each_pair do |from, to|
    test "#{from.to_json} recognized as #{to.to_json}" do
      assert_routing from, to
    end
  end
end
