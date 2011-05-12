# == Schema Information
# Schema version: 20090930163041
#
# Table name: tags
#
#  id                :integer(4)      not null, primary key
#  keyword_id        :integer(4)
#  addressable_id    :integer(4)
#  addressable_type  :string(64)
#  notes             :text
#  ref_id            :integer(4)
#  pages             :string(255)
#  pg_start          :string(8)
#  pg_end            :string(8)
#  proj_id           :integer(4)      not null
#  creator_id        :integer(4)      not null
#  updator_id        :integer(4)      not null
#  updated_on        :timestamp       not null
#  created_on        :timestamp       not null
#  referenced_object :string(255)
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class TagTest < ActiveSupport::TestCase
  #fixtures :tags

  def setup
    set_before_filter_vars # sets $person_id = 1, $proj_id = 1
    @k = Keyword.create!(:keyword => "foo")
    @r = Ref.create!(:title => "Title")
    @oc = OntologyClass.create!(:definition => "Some defintion here.", :written_by => @r)
    Proj.find($person_id).update_attributes(:ontology_namespace => "foo")
    @label_stub = Label.create!(:name => "Foo")
  end

  def test_validity_of_referenced_object_formats
    @k1 = Keyword.create!(:keyword => "bar", :is_xref => true)
    t = Tag.new(:notes => "", :addressable_type => "OntologyClass", :addressable_id => @oc.id, :keyword => @k1, :referenced_object => 'foobar')
    assert !t.valid?
    t.referenced_object = ' foo:bar'
    assert !t.valid?
    t.referenced_object = 'foo: bar'
    assert !t.valid?
    t.referenced_object = 'foo:bar '
    assert !t.valid?
    t.referenced_object = 'thing_that_does_not_match:000' # foo is the default namespace in the test suite
    assert t.valid? 
  end 

  def test_that_referenced_object_is_not_required
    p = Tag.new(:notes => "", :addressable_type => "OntologyClass", :addressable_id => @oc.id, :keyword_id => @k.id)
    assert p.valid?
    assert p.save 
  end

  def test_that_referenced_object_is_not_required_empty_string
    p = Tag.new(:notes => "", :addressable_type => "OntologyClass", :addressable_id => @oc.id, :keyword_id => @k.id, :referenced_object => "")
    assert p.valid?
    assert p.save 
  end

  def test_that_referenced_object_is_not_required_nil
    p = Tag.new(:notes => "", :addressable_type => "OntologyClass", :addressable_id => @oc.id, :keyword_id => @k.id, :referenced_object => nil)
    assert p.valid?
    assert p.save 
  end

  def test_that_tags_with_external_namespaces_are_valid
    ro = "FBbt:010101"
    p = Tag.new(:notes => "", :addressable_type => "OntologyClass", :addressable_id => @oc.id, :keyword_id => @k.id, :referenced_object => ro)
    assert p.valid?
    assert p.save
    assert_equal ro, p.referenced_object 
  end

  def test_validation_of_referenced_object_when_object_is_internal
    p = Tag.new(:notes => "", :addressable_type => "OntologyClass", :addressable_id => @oc.id, :keyword_id => @k.id)
    assert p.valid?
    o = Otu.create!(:name => 'foo')
    p.referenced_object = ":blah"
    assert !p.valid?
    p.referenced_object = ":Otu:#{o.id}"
    assert p.valid?
  end

 def test_validation_of_referenced_object_using_ontology_namespace
    p2 = OntologyClass.create(:definition => "foo", :xref => "foo:0001", :written_by => @r, :obo_label => @label_stub)
   
    p = Tag.new(:addressable_type => "OntologyClass", :addressable_id => @oc.id, :keyword_id => @k.id, :referenced_object => "foo:0002")
    assert !p.valid?
    
    p.referenced_object = "foo:0001"
    assert p.valid?
 end

 def test_referenced_object_object_with_ontology_namespace
    p2 = OntologyClass.create(:definition => "foo", :xref => "foo:0001", :written_by => @r, :obo_label => @label_stub)
    p = Tag.new(:addressable_type => "OntologyClass", :addressable_id => @oc.id, :keyword_id => @k.id, :referenced_object => "foo:0001")
    assert p.save
    assert_equal p2, p.referenced_object_object
 end

 def test_referenced_object_object_with_internal_object
   o = Otu.create!(:name => 'foo') 
   p = Tag.new(:addressable_type => "OntologyClass", :addressable_id => @oc.id, :keyword_id => @k.id, :referenced_object => ":otu:#{o.id}")
   assert p.save 
   assert_equal p.referenced_object_object, o 
 end

  def test_referenced_object_object_with_internal_object_and_case_does_not_matter
   o = Otu.create!(:name => 'foo') 
   p = Tag.new(:addressable_type => "OntologyClass", :addressable_id => @oc.id, :keyword_id => @k.id, :referenced_object => ":Otu:#{o.id}")
   assert p.save 
   assert_equal p.referenced_object_object, o 
 end

 def test_update_referenced_object_to_ontology_namespace_for_ontology_classes
   p1 = OntologyClass.create!(:definition => "Foo", :xref => "foo:0001", :written_by => @r, :obo_label => @label_stub)    
   t = Tag.new(:addressable_type => "OntologyClass", :addressable_id => @oc.id, :keyword_id => @k.id, :referenced_object => ":ontology_class:#{p1.id}")
   assert t.save
   assert_equal ":ontology_class:#{p1.id}", t.referenced_object
   assert t.update_to_ontology_namespace
   assert_equal "foo:0001", t.referenced_object
   assert_equal p1, t.referenced_object_object
 end 

 def test_create_new
    o = Otu.create!(:name => "foo")
    t = Tag.create_new(:keyword => @k, :obj => o)
    assert t.valid?
 end

end
