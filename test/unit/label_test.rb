require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class LabelTest < ActiveSupport::TestCase

  def setup
    set_before_filter_vars
    @ref = Ref.create!
  end

  test "valid label forms" do
    l = Label.new(:name => ' invalid preceeding space')
    assert !l.valid?
    l.name = 'invalid postfixed space '
    assert !l.valid?
    l.name = 'valid with space in middle'
    assert l.valid?
  end
    

  test "ontology_classes_for_plurals" do
     l = Label.create!(:name => "a")
     assert !l.has_definition?
     oc = OntologyClass.create!(:definition => "Foo is a thing with foosball.", :written_by => @ref)
     Sensu.create!(:ref => @ref, :ontology_class => oc, :label => l)
     l.reload
     assert l.has_definition?
  end

  test "named_scope_with_label_from_array" do
    %w(cow moose beaver horse e).each do |l|
      Label.create(:name => l)
    end
    assert_equal ["e", "moose"], Label.with_label_from_array(['moose', 'e']).map(&:name).sort
    assert_equal [], Label.with_label_from_array([]).map(&:name).sort
    assert_equal [], Label.with_label_from_array(['elephant']).map(&:name).sort
  end

  test "has_definition?" do
     l = Label.create!(:name => "a")
     assert !l.has_definition?
     oc = OntologyClass.create!(:definition => "Foo is a thing with foosball.", :written_by => @ref)
     Sensu.create!(:ref => @ref, :ontology_class => oc, :label => l)
     l.reload
     assert l.has_definition?
  end

  test "has_plural?" do
    l = Label.create!(:name => "a")
    l1 = Label.create!(:name => 'as', :plural_of_label => l)
    l.reload
    l1.reload
    assert l.has_plural?
    assert !l1.has_plural?
  end

  test "is_plural?" do
    l = Label.create!(:name => "a")
    l1 = Label.create!(:name => 'as', :plural_of_label => l)
    assert !l.is_plural?
    assert l1.is_plural?
  end

  test "that labels are not pluralized multiple times" do
    l = Label.create!(:name => "a")
    l1 = Label.create!(:name => 'as', :plural_of_label => l)
    l2 = Label.new(:name => 'bs', :plural_of_label => l)
    assert !l2.valid?
  end

  test "all_forms" do
    l = Label.create!(:name => "a")
    l1 = Label.create!(:name => 'as', :plural_of_label => l)
    assert_equal %w(a as), l.all_forms
  end

  test "without_ontology_classes_but_used_in_ontology_class_definitions" do
    l = Label.create!(:name => "foo")
    l1 = Label.create!(:name => 'foos')
    oc = OntologyClass.create!(:definition => "Foo is a thing with foosball.", :written_by => @ref)
    h = {l => [oc]}
    assert_equal h, Label.without_ontology_classes_but_used_in_ontology_class_definitions(:proj_id => $proj_id)
  end

  test "all_labels_for_ontology_class" do
    l = Label.create!(:name => "a")
    l1 = Label.create!(:name => 'as', :plural_of_label => l)
        r = Ref.create!
    oc = OntologyClass.create!(:definition => "Foo is a thing with foosball.", :written_by => @ref)

    s = Sensu.create!(:ref => r, :ontology_class => oc, :label => l)
    assert_equal [l,l1], Proj.find($proj_id).labels.all_for_ontology_class(oc)
  end

  test "synonyms_by_ontology_class" do
    l = Label.create!(:name => "a")
    l1 = Label.create!(:name => 'b')
    oc = OntologyClass.create!(:definition => "Foo is a thing with foosball.", :written_by => @ref)
    s = Sensu.create!(:ref => @ref, :ontology_class => oc, :label => l)
    s1 = Sensu.create!(:ref => @ref, :ontology_class => oc, :label => l1)
    l.reload
    l1.reload
    
    assert_equal [l1], l.synonyms_by_ontology_class(oc)
    assert_equal [l], l1.synonyms_by_ontology_class(oc)
  end
  
  test "that labels tied to ontology classes with xref can not be destroyed" do
    l = Label.create!(:name => "a")
    oc = OntologyClass.create!(:definition => "Bar is not a thing with foosball.", :written_by => @ref, :obo_label => l)
    l.reload
    assert l.destroy 
    oc.reload
    assert oc.obo_label.nil?

    l2 = Label.create!(:name => "b")
    oc.obo_label_id = l2.id
    oc.xref = 'ABC:123'
    oc.save
    oc.reload
    l2.reload
    assert l2.ontology_classes_in_OBO.include?(oc)
   
    assert !l2.destroy 
  end

  test "that label spelling can be changed if not used as obo_labels" do
    l = Label.create!(:name => "a")
    oc = OntologyClass.create!(:definition => "Foo is a thing with foosball.", :written_by => @ref, :obo_label => l)
    l.reload
    
    l.name = "b"
    assert !l.save

    l1 = Label.create!(:name => "c")
    l1.name = "d"
    assert l1.save
    
  end


  def _setup_for_characterization_tests
    @synonym1 = Label.create!(:name => 'synonym1')
    @synonym2 = Label.create!(:name => 'synonym2')
    @homonym = Label.create!(:name => 'homonym')

    @nothing = Label.create!(:name => 'nothing')

    @oc1 = OntologyClass.create!(:definition => "Synonym class.", :written_by => @ref)
    @oc2 = OntologyClass.create!(:definition => "Homonym class1.", :written_by => @ref)
    @oc3 = OntologyClass.create!(:definition => "Homonym class2.", :written_by => @ref)

    @s1 = Sensu.create!(:ref => @ref, :label => @synonym1, :ontology_class => @oc1) 
    @s2 = Sensu.create!(:ref => @ref, :label => @synonym2, :ontology_class => @oc1) 

    @s3 = Sensu.create!(:ref => @ref, :label => @homonym, :ontology_class => @oc2) 
    @s4 = Sensu.create!(:ref => @ref, :label => @homonym, :ontology_class => @oc3) 

    # add some data to confuse
    @ref2 = Ref.create! 
    @s5 = Sensu.create!(:ref => @ref2, :label => @homonym, :ontology_class => @oc3) 
    @s5 = Sensu.create!(:ref => @ref2, :label => @homonym, :ontology_class => @oc2) 

    @proj = Proj.find($proj_id)
    @proj.reload
  end

  test "is_synonym?" do 
    _setup_for_characterization_tests
    assert @synonym1.is_synonym?
    assert @synonym2.is_synonym?
  end

  test "is_homonym?" do
    _setup_for_characterization_tests
    assert @homonym.is_homonym?
  end

 test "that_are_homonyms" do
   _setup_for_characterization_tests
   assert_equal [@homonym], @proj.labels.that_are_homonyms
 end

  test "that_are_synonyms" do
    _setup_for_characterization_tests
    assert_equal [@synonym1, @synonym2], @proj.labels.that_are_synonyms
  end

end
