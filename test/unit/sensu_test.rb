require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class SensuTest < ActiveSupport::TestCase

  def setup
    set_before_filter_vars # sets $person_id = 1, $proj_id = 1
  end

  def create_some_test_data
    # our test data look like this
    
    # label class ref
    # A     1     r1     0
    # B     2     r2     1
    # C     3     r3     2
    # D     3     r3     3
    # E     4     r4     4 
    # E     5     r4     5
    
    # they exemplify three things
    # 1) synonyms (C and D for 3)  - different labels same ontology_class 
    # 2) homonyms (E for 4 and 5)  - different ontology_class, same label
    # 3) acts (e.g. homonymization of E in r5) - either of above in same ref

    @refs = []
    %w/r1 r2 r3 r4/.each do |r| 
     @refs.push Ref.create!(:title => r )
    end 

    @labels = []
    %w/A B C D E/.each do |lbl|
      @labels.push Label.create!(:name => lbl)
    end

    @ontology_classes = []
    %w/A B C D E/.each do |oc|
      @ontology_classes.push OntologyClass.create!(:definition => oc, :written_by => @refs[0]) # we don't use written_by, so just borrow a ref reference
    end
    
    @s0 = Sensu.create!(:label => @labels[0], :ontology_class => @ontology_classes[0], :ref => @refs[0])
    @s1 = Sensu.create!(:label => @labels[1], :ontology_class => @ontology_classes[1], :ref => @refs[1])
    @s2 = Sensu.create!(:label => @labels[2], :ontology_class => @ontology_classes[2], :ref => @refs[2])
    @s3 = Sensu.create!(:label => @labels[3], :ontology_class => @ontology_classes[2], :ref => @refs[2])
    @s4 = Sensu.create!(:label => @labels[4], :ontology_class => @ontology_classes[3], :ref => @refs[3])
    @s5 = Sensu.create!(:label => @labels[4], :ontology_class => @ontology_classes[4], :ref => @refs[3])
  
    @proj = Proj.find($proj_id) 
  end

  def test_named_scope_by_ontology_class
    create_some_test_data
    assert_equal 2, @proj.sensus.by_ontology_class(@ontology_classes[2]).size
    assert_equal 1, @proj.sensus.by_ontology_class(@ontology_classes[4]).size
  end

  def test_named_scope_by_label
    create_some_test_data
    assert_equal 2, @proj.sensus.by_label(@labels[4]).size
    assert_equal 1, @proj.sensus.by_label(@labels[0]).size
  end

  def test_named_scope_excluding_label
    create_some_test_data
    assert_equal 5, @proj.sensus.excluding_label(@labels[0]).size
    assert_equal 4, @proj.sensus.excluding_label(@labels[4]).size
  end

  def test_named_scope_excluding_ontology_class
    create_some_test_data
    assert_equal 5, @proj.sensus.excluding_ontology_class(@ontology_classes[0]).size
    assert_equal 4, @proj.sensus.excluding_ontology_class(@ontology_classes[2]).size
  end

  def test_acts_of_synonymy
    create_some_test_data
    assert_equal 0, @s1.acts_of_synonymy_for_ref.size 
    assert_equal 1, @s2.acts_of_synonymy_for_ref.size
    assert_equal [[@labels[2], @labels[3]]], @s2.acts_of_synonymy_for_ref
  end

  # these should be rare, or mistakes by data-entry or author
  def test_acts_of_homonymy
    create_some_test_data
    assert_equal 0, @s1.acts_of_homonymy_for_ref.size 
    assert_equal 1, @s5.acts_of_homonymy_for_ref.size
    assert_equal [[@ontology_classes[3], @ontology_classes[4]]], @s5.acts_of_homonymy_for_ref
  end

end
