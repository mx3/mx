require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class OntologyRelationshipTest < ActiveSupport::TestCase

  def setup
    set_before_filter_vars
    @ref_stub = Ref.create!(:title => 'Foo') 
    @object_relationship_stub = ObjectRelationship.create!(:interaction => "Foo") 
    @label_stub = Label.create!(:name => "Foo")
    Proj.find($proj_id).update_attributes(:ontology_namespace => "Foo") 
  end

  def setup_for_simple_tests
    @oc1 = OntologyClass.create!(:definition => "Foo.", :written_by => @ref_stub, :obo_label => @label_stub ) 
    @oc2 = OntologyClass.create!(:definition => "Bar.", :written_by => @ref_stub, :obo_label => @label_stub ) 
    @oc1.reload
    @oc2.reload
    @or = OntologyRelationship.create!(:ontology_class1 => @oc1, :ontology_class2 => @oc2, :object_relationship => @object_relationship_stub)
  end

  test "that named_scope where_both_ontology_classes_have_xrefs fails when neither related class has xref" do
    setup_for_simple_tests
    assert_equal [], @oc1.primary_relationships.where_both_ontology_classes_have_xrefs
    assert_equal [], @oc2.primary_relationships.where_both_ontology_classes_have_xrefs
  end

  test "that named_scope where_both_ontology_classes_have_xrefs fails when one related class has xref" do
    setup_for_simple_tests
    @oc1.xref = "Foo:123" 
    @oc1.save 

    assert_equal [], @oc1.primary_relationships.where_both_ontology_classes_have_xrefs
    assert_equal [], @oc2.primary_relationships.where_both_ontology_classes_have_xrefs
  end

  test "that named_scope where_both_ontology_classes_have_xrefs works when both related classes have xrefs" do
    setup_for_simple_tests
    @oc1.xref = "Foo:123" 
    @oc2.xref = "Foo:124" 
    @oc1.save
    @oc2.save 
    assert_equal [@or], @oc1.primary_relationships.where_both_ontology_classes_have_xrefs
  end

end
