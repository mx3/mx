# == Schema Information
# Schema version: 20090930163041
#
# Table name: projs
#
#  id                            :integer(4)      not null, primary key
#  name                          :string(255)     not null
#  hidden_tabs                   :text
#  public_server_name            :string(255)
#  unix_name                     :string(32)
#  public_controllers            :text
#  public_tn_criteria            :string(32)
#  repository_id                 :integer(4)
#  starting_tab                  :string(32)      default("otu")
#  default_ontology_id           :integer(4)
#  default_content_template_id   :integer(4)
#  gmaps_API_key                 :string(90)
#  creator_id                    :integer(4)      not null
#  updator_id                    :integer(4)      not null
#  updated_on                    :timestamp       not null
#  created_on                    :timestamp       not null
#  ontology_namespace            :string(32)
#  default_ontology_term_id      :integer(4)
#  obo_remark                    :text
#  ontology_inclusion_keyword_id :integer(4)
#  ontology_exclusion_keyword_id :integer(4)
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


require 'proj'

class ProjTest < ActiveSupport::TestCase  
  self.use_instantiated_fixtures  = true
  
  fixtures :projs, :genes
   
  def setup
    $person_id = 1
    $proj_id = 1
  end

  def test_name_from_fixture
    assert_equal "Hymenoptera horror show", @projs['projs1']['name']
  end
    
  def test_projs_total_from_fixtures
    assert_equal 6, Proj.count
  end
  
   def test_projs1_gene_count          
    proj1 = @projs['projs1'].find
    assert_equal 3, proj1.genes.count
  end 
  
   def _setup_for_destroy_or_merge_tests
    $person_id = 1
    @p = Proj.new(:name => "Foo")
    assert_equal true, @p.save
    $proj_id = @p.id  

    @o = Otu.create!(:name => "Blorf")
    @o1 = Otu.create!(:name => "Smorf", :syn_with_otu_id => @o.id )
    @o2 = Otu.create!(:name => "Glorf")
    
    @ct = ContentTemplate.create!(:name => "Bar")
    @cont_type = ContentType.create!(:name => "Blorf")
    @ct.content_types << @cont_type
    @ct.save

    @geog = Geog.create(:name => "Place")

    namespace = Namespace.create!(:name => "name", :short_name => 'name')

    @ce = Ce.create!(:verbatim_label => "Meh!", :geog_id => @geog.id)
    @s = Specimen.create!(:ce => @ce)

     # TODO: Add an Identifier or two

    @chr = Chr.create!(:name => "Foo")
    @k = Keyword.create!(:keyword => "Foo")

    @p.reload
   end 
 
   def test_destroy_sortof
     _setup_for_destroy_or_merge_tests
     assert @p.destroy
  end

  def test_merge_to_project_sort_of
     _setup_for_destroy_or_merge_tests
     @p2 = Proj.new(:name => "Bar")
     assert @p2.save
     assert @p.merge_to_project(:proj_id => @p2.id, :person_id => 1)

     @p2.reload

     assert_equal 3, @p2.otus.count
     assert_equal 1, @p2.content_types.count
     assert_equal 1, @p2.content_templates.count
     assert_equal 1, @p2.specimens.count
     assert_equal 1, @p2.chrs.count
     assert_equal 1, @p2.keywords.count
  end

  def test_merge_to_proj_with_postfix_true
     _setup_for_destroy_or_merge_tests
     @p2 = Proj.new(:name => "Bar")
     assert @p2.save
     assert @p.merge_to_project(:proj_id => @p2.id, :person_id => 1, :postfix_otu_names => true, :postfix_chr_names => true)
     @p2.reload

     @o.reload
     @chr.reload
     assert_equal "Blorf [from: #{@p.id}]", @o.name
     assert_equal "Foo [from: #{@p.id}]", @chr.name
  end

  def test_merge_to_proj_with_shared_content_type_names
     _setup_for_destroy_or_merge_tests
     @p2 = Proj.new(:name => "Bar")
     assert @p2.save

     $proj_id = @p2.id
     @cont_type2 = ContentType.create!(:name => "Blorf") # should be deleted after merge transfer

     assert @p.merge_to_project(:proj_id => @p2.id, :person_id => 1, :postfix_otu_names => true, :postfix_chr_names => true)
     @p2.reload
  end
  
  test "that projects can not share listed public_server_names" do
    @p1 = Proj.create!(:name => "foo", :public_server_name => "foo.bar.com;stuff.things.org;foo.things.net")
    @p2 = Proj.new(:name => "bar", :public_server_name => "foo.bar.com")
    assert !@p2.valid?
    @p2.public_server_name =  "stuff.things.org"
    assert !@p2.valid?
    @p2.public_server_name =  "foo.things.net"
    assert !@p2.valid?
    @p2.public_server_name =  "get.this.right.com"
    assert @p2.valid?
  end

  test "that return_by_public_server_name works for URLs at different points in string" do
    @p1 = Proj.create!(:name => "foo", :public_server_name => "foo.bar.com;stuff.things.org;foo.things.net")
    assert Proj.return_by_public_server_name('foo.bar.com')
    assert Proj.return_by_public_server_name('stuff.things.org')
    assert Proj.return_by_public_server_name('foo.things.net')
  end

  test "that substrings will not match on public_server_name" do
    @p1 = Proj.create!(:name => "foo", :public_server_name => "foo.bar.com;stuff.things.org;foo.things.net")
    assert !Proj.return_by_public_server_name('bar')
    assert !Proj.return_by_public_server_name('com;stuff.things')
    assert !Proj.return_by_public_server_name('things.org')
    assert !Proj.return_by_public_server_name('foo')
    assert !Proj.return_by_public_server_name('net')
    assert !Proj.return_by_public_server_name('foo.bar')
  end
end
