require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require File.expand_path(File.dirname(__FILE__) + "/../../lib/ontology/obo2mx")

class Obo2mxTest < ActiveSupport::TestCase

  def setup
    set_before_filter_vars
    @proj = Proj.find($proj_id) 
  end

  def setup_for_OBO_related_tests
    ObjectRelationship.create!(:interaction => "is_a")
    ObjectRelationship.create!(:interaction => "part_of")
    @proj.reload
    @obo_file = File.read(File.dirname(__FILE__) + '/../fixtures/test_files/cell.obo')
  end
  
  test "that compare runs" do 
    setup_for_OBO_related_tests
    assert compare_result = Ontology::Obo2mx::compare(:file => @obo_file)

    assert_equal 3, compare_result[:object_relationships].length # creates 2 default, 1 Typdef
    assert_equal true, compare_result[:object_relationships].values.first.new_record? # only one typdef in the test file

    assert compare_result[:labels].keys.include?('cochlear outer hair cell')
    assert compare_result[:labels].keys.include?('pressoreceptor cell')
    assert compare_result[:labels].keys.include?('white blood cell')
    assert compare_result[:labels].keys.include?('blue chromatophore')

    assert sensu = compare_result[:sensus]['CL:0000018'].first

    assert_equal 'A male germ cell that develops from the haploid secondary spermatocytes. Without further division, spermatids undergo structural changes and give rise to spermatozoa.', sensu.ontology_class.definition
    assert_equal 'spermatid', sensu.label.name
    assert  sensu.ref.new_record?

    assert orel = compare_result[:ontology_relationships]['CL:0000002'].first
    assert_equal 'CL:0000002', orel.ontology_class1.xref
    assert_equal 'CL:0000010', orel.ontology_class2.xref
    assert_equal 'is_a', orel.object_relationship.interaction
    assert orel.new_record?
  end

  test "that import works" do 
    setup_for_OBO_related_tests
    assert compare_result = Ontology::Obo2mx::compare(:file => @obo_file)
    @proj = Proj.create!(:name => 'Test import')
    assert Ontology::Obo2mx::import(:compare_result => compare_result, :person_id => 1, :proj_id => @proj.id) 
  end

end
