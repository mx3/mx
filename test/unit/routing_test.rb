require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require File.expand_path(File.dirname(__FILE__) + "/../../config/routes.rb")

class RoutingTest < ActionController::TestCase

  # Recognizes
  {
    {:controller => 'projs',   :action => 'index' } =>
    '/projs',

    {:controller => 'otus',    :action => 'new',       :proj_id => '1'} =>
    "/projects/1/otus/new",

    {:controller => 'otus',    :action => 'show',      :proj_id => '1', :id => "1"} =>
    "/projects/1/otus/1",

    {:controller => 'otus',    :action => 'edit',      :proj_id => '1', :id => "1"} =>
    "/projects/1/otus/1/edit",

    {:controller => 'otus',    :action => 'batch_load',      :proj_id => '1', } =>
    "/projects/1/otus/batch_load",

    {:controller => 'otus',    :action => 'show',      :proj_id => '1', :id => "1", :format => "json"} =>
    "/projects/1/otus/1.json",

    {:controller => 'otus',    :action => 'show_tags',   :proj_id => '1', :id => "1", :format => "json"} =>
    "/projects/1/otus/1/show_tags.json",

    {:controller => 'admin',  :action => 'new_proj'} =>
    "/admin/new_proj",

    # TODO: (later) Should reformulate to hit CodingController CRUD, then redirect
    {:controller => "mxes",     :action => 'show_code', :proj_id => "1", :otu_id => "1", :chr_id => "1", :id => "1"} =>
    "/projects/1/mxes/1/code/1/1",

    {:controller => "mxes",     :action => 'fast_code', :proj_id => "1", :position => "1", :chr_state_id => "1", :mode => "row", :otu_id => "1", :chr_id => "1", :id => "1"} =>
    "/projects/1/mxes/1/fast_code/row/1/1/1/1",

    {:controller => "api/ontology", :action => "obo_file", :proj_id => "1"} =>
    "/projects/1/api/ontology/obo_file",

    {:controller => "api/ontology", :action => "obo_file"} =>
    "/api/ontology/obo_file",

  }.each_pair do |from, to|
    test "#{from.to_json} recognized as #{to.to_json}" do
      assert_recognizes from, to
    end
  end

  # Generates
  {

    "/projects/1/chrs/1" =>
    {controller: "chrs", action: "show", proj_id: "1", id: "1"},

    "/projects/1/public/chrs" =>
    {controller: "public/chrs", proj_id: "1", action: "index"},

   # {controller: "public/otu", action: "show", proj_id: "1", id: "1"}
  }.each_pair do |from, to|
    test "#{from.to_json} recognized as #{to.to_json}" do
      assert_generates from, to
    end
  end

  # Routing
  {
    "/projects/1/public/chrs/1" =>
    {:controller => "public/chrs", :action => 'show', :proj_id => "1", :id => "1"},

    "/projects/1/public/chrs" =>
    {:controller => "public/chrs", :action => 'index',:proj_id => "1"},

    "/projects/1/otus/1" =>
    { proj_id: "1", controller: "otus", action: "show", id: "1"}
  }.each_pair do |from, to|
    test "#{from.to_json} recognized as #{to.to_json}" do
      assert_routing from, to
    end
  end
end
