require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class OntologyClassTest < ActiveSupport::TestCase

  # Several of the tests here are mashups of OntologyClass and OntologyRelationship, if in doubt place place/leave these here

  def setup
    set_before_filter_vars
    @proj = Proj.find($proj_id)

    @isa = ObjectRelationship.create!(:interaction => 'isa')
    @partof = ObjectRelationship.create!(:interaction => 'partof')

    @ref_stub = Ref.create!
    @label_stub = Label.create!(:name => "Blorf")
  end

  test "that reasons for obsoleting classes are required" do
    @o = OntologyClass.new(:definition => 'Foos and bars', :written_by => @ref_stub, :is_obsolete => true)
    assert !@o.valid?
    assert !@o.errors[:is_obsolete_reason].empty?

    @o.is_obsolete_reason = "Some reason."
    assert @o.valid?

    @o.is_obsolete = nil
    assert !@o.valid?
    assert !@o.errors[:is_obsolete].empty?
  end

  test "xref can't be set before an OBO label is provided" do
    @o = OntologyClass.new(:definition => 'Foos and bars', :written_by => @ref_stub, :xref => 'Foo:123')
    assert !@o.valid?
    assert !@o.errors[:obo_label_id].empty?
  end

  test "largest_xref_identifier" do
    @o = OntologyClass.create!(:definition => 'Foos and bars', :written_by => @ref_stub, :xref => "foo:1234", :obo_label => @label_stub)
    @o1 = OntologyClass.create!(:definition => 'Bars and foos', :written_by => @ref_stub, :xref => "foo:12", :obo_label => @label_stub)
    assert_equal 1234, OntologyClass.largest_xref_identifier(:prefix => "foo", :proj_id => @proj.id)
  end

  test "fill_blank_xrefs" do
    @o = OntologyClass.create!(
                      :definition => 'Foos and bars.',
                      :written_by => @ref_stub,
                      :obo_label => @label_stub)
    assert @o.xref.nil?

    @o.reload # necessary to refresh the sensus, otherwise generate_xrefs will try and create one

    assert !OntologyClass.generate_xrefs(:proj_id => @proj.id, :prefix => "Foo") # no :ontology_classes
    assert !OntologyClass.generate_xrefs(:ontology_classes => [@o], :prefix => "Foo") # no :proj_id
    assert !OntologyClass.generate_xrefs(:ontology_classes => [@o], :proj_id => @proj.id) # no :prefix

    OntologyClass.generate_xrefs(:ontology_classes => [@o], :proj_id => @proj.id, :prefix => "Foo")
    @o.reload
    assert_equal "Foo:0000000", @o.xref

    @o1 = OntologyClass.create!(:definition => 'Foos in bars.', :written_by => @ref_stub, :xref => 'Foo:994', :obo_label => @label_stub)
    @o2 = OntologyClass.create!(:definition => 'Foos in barz.', :written_by => @ref_stub, :obo_label => @label_stub)
    @o2.reload
    OntologyClass.generate_xrefs(:ontology_classes => [@o2], :proj_id => @proj.id, :prefix => "Foo")

    assert_equal "Foo:0000995", @o2.xref
  end


  test "preferred label logic" do
    @l1 = Label.create!(:name => "foo")
    @l2 = Label.create!(:name => "bar")
    @l3 = Label.create!(:name => "blorf")

    @o = OntologyClass.create!(:definition => 'Foos and bars', :written_by => @ref_stub, :obo_label => @l1)

    # a background sensu is created here, reload so another is not found
    @o.reload

    # bind labels to classes
    @s1 = Sensu.new(:label => @l2, :ref => @ref_stub)
    @s2 = Sensu.new(:label => @l3, :ref => @ref_stub)

    @o.sensus << @s1
    @o.save
    @o.sensus << @s2
    @o.save

    @o.reload

    assert_equal 3, @o.labels.size # one for the obo_label, one for each of the sensus

    assert_equal 2, @s1.position
    assert_equal 3, @s2.position

    assert_equal 'foo', @o.label_name(:type => :preferred) # foo was the first to be added

    # reverse the order
    @o.sensus.each_with_index do |s,i|
      s.position = 3 - i
      s.save
    end

    @o.reload
    assert_equal 'blorf', @o.label_name(:type => :preferred)

    @s1.destroy
    @s2.destroy
    assert_equal 'foo', @o.label_name(:type => :preferred)

    @o.sensus.destroy_all

    assert_equal 'NO LABEL PROVIDED', @o.label_name(:type => :preferred)
  end

  test "records with xrefs can not be destroyed in typical fashion" do
    o = OntologyClass.create!(:definition => 'Foos and bars', :xref => "FOO:123", :written_by => @ref_stub, :obo_label => @label_stub)
    assert !o.destroy
    assert !o.errors[:xref].empty?
  end

  test "setting a obo label id automatically adds to self#labels if not present" do
    l = Label.create!(:name => "foo")
    o = OntologyClass.create!(:definition => 'Foos and bars', :written_by => @ref_stub, :obo_label => l)
    o.reload
    assert_equal [l], o.labels
  end

  test "xrefs must be in foo:bar format" do
      o = OntologyClass.new(:definition => 'Foos and bars', :written_by => @ref_stub, :xref => 'blorf', :obo_label => @label_stub)
      assert !o.valid?
      o.xref = " asdf:1234" # no preceeding spaces
      assert !o.errors[:xref].empty?
      assert !o.valid?
      o.xref = "asdf:1234 " # no postifixed spaces
      assert o.errors[:xref]
      assert !o.valid?
      o.xref = "asdf:asdf"  # digits not text
      assert !o.valid?
      o.xref = "asdf:1234"  # digits not text
      assert o.valid?
  end

  test "defintion is required" do
    o = OntologyClass.new
    assert !o.valid?
  end

  def setup_for_simple_plural_tests
    @o = OntologyClass.create!(:definition => 'Foos and bars', :written_by => @ref_stub)
    @l1 = Label.create!(:name => "foo")
    @l2 = Label.create!(:name => "foos", :plural_of_label_id => @l1.id)
    @l3 = Label.create!(:name => "bar")

    # bind labels to classes
    @s = Sensu.create!(:label => @l1, :ontology_class => @o, :ref => @ref_stub)
    @s1 = Sensu.create!(:label => @l3, :ontology_class => @o, :ref => @ref_stub)
  end

  test "that all_labels_through_sensus has_many works" do
    setup_for_simple_plural_tests
    @another_ref_stub = Ref.create!
    Sensu.create!(:label => @l1, :ontology_class => @o, :ref => @another_ref_stub)

    assert_equal [@l3, @l1, @l1], @o.all_labels_through_sensus.ordered_by_name
  end

  test "that labels_through_sensus has_many returns unique labels" do
    setup_for_simple_plural_tests
    @another_ref_stub = Ref.create!
    Sensu.create!(:label => @l1, :ontology_class => @o, :ref => @another_ref_stub)
    assert_equal [@l3, @l1], @o.labels.ordered_by_name
  end

  test "that plural labels return ontology classes when tied through singular of label in sensu" do
    setup_for_simple_plural_tests
    assert_equal [@o], Proj.find($proj_id).ontology_classes.by_label_including_plurals(@l2.name) # String
    assert_equal [@o], Proj.find($proj_id).ontology_classes.by_label_including_plurals(["don't match and single quote test", @l2.name]) # Array
    assert_equal [], Proj.find($proj_id).ontology_classes.by_label_including_plurals() # nil
  end

  test "all labels includes plural forms" do
    setup_for_simple_plural_tests
    @o.reload
    assert_equal %w/bar foo foos/, @o.all_labels
  end

  test "add IP vote on create" do
     o = OntologyClass.create!(:definition => 'Foos and bars', :illustration_IP_vote => '127.0.0.1', :written_by => @ref_stub)
     assert_equal 1, o.illustration_IP_votes.size
     assert_equal ['127.0.0.1'], o.illustration_IP_votes
  end

  test "add IP vote post create" do
     o = OntologyClass.create!(:definition => 'Foos and bars', :written_by => @ref_stub)
     assert_equal 0, o.illustration_IP_votes.size
     o.illustration_IP_vote = '127.0.0.1'
     o.save
     assert_equal 1, o.illustration_IP_votes.size
     assert_equal ['127.0.0.1'], o.illustration_IP_votes
  end

  test "add illustration IP votes is initialized on create" do
     o = OntologyClass.create!(:definition => 'Foos and bars', :written_by => @ref_stub)
     assert_equal 0, o.illustration_IP_votes.size
  end

  test "is_a_children" do
    _setup_for_tree_logic_tests
    assert_equal [@a], @b.is_a_children
    assert_equal [@c], @f.is_a_children
    assert_equal [@b], @d.is_a_children
    assert_equal [], @a.is_a_children
  end

  test "is_a_parents" do
    _setup_for_tree_logic_tests
    assert_equal [@b], @a.is_a_parents
    assert_equal [@f], @c.is_a_parents
    assert_equal [], @i.is_a_parents
    assert_equal [@d], @b.is_a_parents
  end

  test "is_a_descendants" do
    _setup_for_tree_logic_tests
    assert_equal [@a, @b], @d.is_a_descendants.sort{|a,b| a.definition <=> b.definition }
    assert_equal [@e], @i.is_a_descendants
    assert_equal [], @a.is_a_descendants
  end

  test "is_a_ancestors" do
    _setup_for_tree_logic_tests
    assert_equal [@b, @d], @a.is_a_ancestors
    assert_equal [@f], @c.is_a_ancestors
    assert_equal [@i], @e.is_a_ancestors
  end

  # Uses is_a inference
  test "part_of_children" do
    _setup_for_tree_logic_tests
    assert_equal [@a], @c.part_of_children
    assert_equal [@a, @c], @g.part_of_children.sort{|a,b| a.definition <=> b.definition }
    assert_equal [@a, @b], @i.part_of_children.sort{|a,b| a.definition <=> b.definition } # through is_a
    assert_equal [@a], @f.part_of_children # through is_a
    assert_equal [], @a.part_of_children   # through is_a
  end

  # Uses is_a inference
  test "part_of_parents" do
    _setup_for_tree_logic_tests
    assert_equal [@g, @h], @c.part_of_parents.sort{|a,b| a.definition <=> b.definition }
    assert_equal [@e], @b.part_of_parents
    assert_equal [], @e.part_of_parents
    assert_equal [@c, @e, @g], @a.part_of_parents.sort{|a,b| a.definition <=> b.definition }
  end

  test "parents_by_relationship" do
    _setup_for_tree_logic_tests
    assert_equal [@g, @h], @c.parents_by_relationship('part_of').sort{|a,b| a.definition <=> b.definition }
    assert_equal [@e], @b.parents_by_relationship('part_of')
    assert_equal [], @e.parents_by_relationship('part_of')
    assert_equal [@c, @e, @g], @a.parents_by_relationship('part_of').sort{|a,b| a.definition <=> b.definition }
  end

  # infers across is_a
  test "part_of_ancestors" do
    _setup_for_tree_logic_tests
    assert_equal [@c, @e, @f, @g, @h, @i], @a.part_of_ancestors.sort{|a, b| a.definition <=> b.definition}
    assert_equal [@e, @i], @b.part_of_ancestors.sort{|a, b| a.definition <=> b.definition}
    assert_equal [], @i.part_of_ancestors
    assert_equal [@g, @h], @c.part_of_ancestors.sort{|a, b| a.definition <=> b.definition}
  end

  # infers across is_a
  test "part_of_descendants" do
    _setup_for_tree_logic_tests
    assert_equal [@a, @b], @i.part_of_descendants.sort{|a, b| a.definition <=> b.definition}
    assert_equal [@a, @c, @f], @h.part_of_descendants.sort{|a, b| a.definition <=> b.definition}
    assert_equal [], @a.part_of_descendants
    assert_equal [@a], @f.part_of_descendants.sort{|a, b| a.definition <=> b.definition}
    assert_equal [@a, @c], @g.part_of_descendants.sort{|a, b| a.definition <=> b.definition}
  end

  test "immediate parent of part_of heirarchy when self has only immediate is_a relationships" do
  end

  test "part_of decendants including through is_a relationships" do
  end

  test "logical relatives for parents" do
    _setup_for_tree_logic_tests

    # given default settings this finds all the OntologyClasses that @a is part_of
    foo = @a.logical_relatives(:direction => :parents) # defaults to children

    assert_equal %w(C E F G H I), foo.keys.sort{|a, b| a.definition <=> b.definition}.collect{|p| p.definition}
    assert_equal true, foo[@e] # assert a redundancy
    assert_equal true, foo[@g]

    assert_equal nil, foo[@a]   # @a is not in our result
    assert_equal nil, foo[@b]   # neither is @b
    assert_equal nil, foo[@d]   # neither is @d
    assert_equal false, foo[@f]
    assert_equal false, foo[@h]
    assert_equal false, foo[@i]
  end

  test "related_ontology_relationships with mixed relationships" do
    _setup_for_tree_like_tests
    @r2 = ObjectRelationship.create!(:interaction => "is_a")
    @o18 = OntologyRelationship.create!(:ontology_class1 => @p8, :ontology_class2 => @p1, :object_relationship => @r2)

    assert_equal 8, @p1.related_ontology_relationships(:relationship_type  => [@r.id, @r2.id]).size
    assert_equal 3, @p2.related_ontology_relationships(:relationship_type  => [@r.id, @r2.id]).size
    assert_equal 2, @p3.related_ontology_relationships(:relationship_type  => [@r.id, @r2.id]).size
    assert_equal 0, @p4.related_ontology_relationships(:relationship_type  => [@r.id, @r2.id]).size
    assert_equal 0, @p5.related_ontology_relationships(:relationship_type  => [@r.id, @r2.id]).size
    assert_equal 0, @p6.related_ontology_relationships(:relationship_type  => [@r.id, @r2.id]).size
    assert_equal 0, @p7.related_ontology_relationships(:relationship_type  => [@r.id, @r2.id]).size
    assert_equal 0, @p8.related_ontology_relationships(:relationship_type  => [@r.id, @r2.id]).size

    assert_equal 3, @p1.related_ontology_relationships(:max_depth => 1,:relationship_type  => [@r.id, @r2.id]).size
  end

  test "related_ontology_relationships" do
    _setup_for_tree_like_tests
    assert_equal 7, @p1.related_ontology_relationships.size
    assert_equal 3, @p2.related_ontology_relationships.size
    assert_equal 2, @p3.related_ontology_relationships.size
    assert_equal 0, @p4.related_ontology_relationships.size
    assert_equal 0, @p5.related_ontology_relationships.size
    assert_equal 0, @p6.related_ontology_relationships.size
    assert_equal 0, @p7.related_ontology_relationships.size
    assert_equal 0, @p8.related_ontology_relationships.size

    assert_equal 2, @p1.related_ontology_relationships(:max_depth => 1).size
  end

  test "newick_string" do
    _setup_for_tree_like_tests
    # slap some labels on the classes created above
    %w/A B C D E F G H/.each do |l|
      label = Label.create!(:name => l)
      Sensu.create!(:label => label, :ontology_class => OntologyClass.find_by_definition(l), :ref => @ref_stub)
    end
    assert_equal "('A',('B',('D','E','F'),'C',('G','H')));", Ontology::Visualize::Newick.newick_string(:ontology_class => @p1, :color => nil)
  end

  test "newick_string with depth" do
    _setup_for_tree_like_tests
    # slap some labels on the classes created above
    %w/A B C D E F G H/.each do |l|
      label = Label.create!(:name => l)
      Sensu.create!(:label => label, :ontology_class => OntologyClass.find_by_definition(l), :ref => @ref_stub)
    end
    assert_equal "('A','B','C');", Ontology::Visualize::Newick.newick_string(:ontology_class => @p1, :color => nil, :max_depth => 2, :hilight_depth => 2)
  end

  test "js_hash" do
    _setup_for_tree_like_tests
    assert_equal 2, @p1.child_ontology_relationships.size
    assert_equal 3, @p2.child_ontology_relationships.size
    assert_equal 2, @p3.child_ontology_relationships.size
    assert_equal 0, @p8.child_ontology_relationships.size
    assert_equal "{A:{B:{D,E,F},C:{G,H}}}", @p1.js_hash(:key_is_id => false)
  end

  test "logical relatives for children" do
    _setup_for_tree_logic_tests
    foo = @h.logical_relatives(:direction => :children) # defaults to children
    assert_equal %w(A C F), foo.keys.sort{|a, b| a.definition <=> b.definition}.collect{|p| p.definition}
  end

  test 'child_ontology_classes' do
    _setup_for_tree_logic_tests
    assert_equal [@a], @b.child_ontology_classes
    assert_equal [@b], @d.child_ontology_classes
    assert_equal [@f], @h.child_ontology_classes
    assert_equal [@b,@a], @e.child_ontology_classes
    assert_equal [], @a.child_ontology_classes
  end

  test 'parent_ontology_classes' do
    _setup_for_tree_logic_tests
    assert_equal [@b, @c, @e, @g], @a.parent_ontology_classes # see redudant
    assert_equal [], @g.parent_ontology_classes
    assert_equal [@h], @f.parent_ontology_classes
  end

   test 'immediately_related_ontology_classes' do
    _setup_for_tree_logic_tests
    assert_equal [@a, @b, @i], @e.immediately_related_ontology_classes # .sort{|a, b| a.definition <=> b.definition }
    assert_equal [@a, @f, @g], @c.immediately_related_ontology_classes.sort{|a, b| a.definition <=> b.definition }
    assert_equal [@c, @h], @f.immediately_related_ontology_classes.sort{|a, b| a.definition <=> b.definition }
    assert_equal [@f], @h.immediately_related_ontology_classes.sort{|a, b| a.definition <=> b.definition }
   end

  ## helpers

  def _setup_for_tree_like_tests
    # part_of relationships
    # a
    # b    c
    # def  gh
    @p1 = OntologyClass.create!(:definition => "A", :written_by => @ref_stub)
    @p2 = OntologyClass.create!(:definition => "B", :written_by => @ref_stub)
    @p3 = OntologyClass.create!(:definition => "C", :written_by => @ref_stub)
    @p4 = OntologyClass.create!(:definition => "D", :written_by => @ref_stub)
    @p5 = OntologyClass.create!(:definition => "E", :written_by => @ref_stub)
    @p6 = OntologyClass.create!(:definition => "F", :written_by => @ref_stub)
    @p7 = OntologyClass.create!(:definition => "G", :written_by => @ref_stub)
    @p8 = OntologyClass.create!(:definition => "H", :written_by => @ref_stub)

    @r = ObjectRelationship.create!(:interaction => "part_of")
    @r2 = ObjectRelationship.create!(:interaction => "is_a")

    @o12 = OntologyRelationship.create!(:ontology_class1_id => @p2.id, :ontology_class2_id => @p1.id, :object_relationship_id => @r.id)
    @o13 = OntologyRelationship.create!(:ontology_class1_id => @p3.id, :ontology_class2_id => @p1.id, :object_relationship_id => @r.id)

    @o24 = OntologyRelationship.create!(:ontology_class1_id => @p4.id, :ontology_class2_id => @p2.id, :object_relationship_id => @r.id)
    @o25 = OntologyRelationship.create!(:ontology_class1_id => @p5.id, :ontology_class2_id => @p2.id, :object_relationship_id => @r.id)
    @o26 = OntologyRelationship.create!(:ontology_class1_id => @p6.id, :ontology_class2_id => @p2.id, :object_relationship_id => @r.id)

    @o37 = OntologyRelationship.create!(:ontology_class1_id => @p7.id, :ontology_class2_id => @p3.id, :object_relationship_id => @r.id)
    @o38 = OntologyRelationship.create!(:ontology_class1_id => @p8.id, :ontology_class2_id => @p3.id, :object_relationship_id => @r.id)
  end

  def _setup_for_tree_logic_tests
    # note this is inverted, i.e. ancestors/children are down, descendants/parents are up
    # * -> is a
    # @ -> part of
    #                    a                 children
    #                 *     @                 |
    #                b       c                |
    #              *   @   *   @           parents
    #              d   e   f   g
    #                  *   @
    #                  i   h

    # AND two redundancies : a@e, a@g

    @a = OntologyClass.create!(:definition => "A", :written_by => @ref_stub)
    @b = OntologyClass.create!(:definition => "B", :written_by => @ref_stub)
    @c = OntologyClass.create!(:definition => "C", :written_by => @ref_stub)
    @d = OntologyClass.create!(:definition => "D", :written_by => @ref_stub)
    @e = OntologyClass.create!(:definition => "E", :written_by => @ref_stub)
    @f = OntologyClass.create!(:definition => "F", :written_by => @ref_stub)
    @g = OntologyClass.create!(:definition => "G", :written_by => @ref_stub)
    @h = OntologyClass.create!(:definition => "H", :written_by => @ref_stub)
    @i = OntologyClass.create!(:definition => "I", :written_by => @ref_stub)

    @rp = ObjectRelationship.create!(:interaction => "part_of")
    @ri = ObjectRelationship.create!(:interaction => "is_a")

    @oAB = OntologyRelationship.create!(:ontology_class1 => @a, :ontology_class2 => @b, :object_relationship => @ri)
    @oAC = OntologyRelationship.create!(:ontology_class1 => @a, :ontology_class2 => @c, :object_relationship => @rp)
    @oBD = OntologyRelationship.create!(:ontology_class1 => @b, :ontology_class2 => @d, :object_relationship => @ri)
    @oBE = OntologyRelationship.create!(:ontology_class1 => @b, :ontology_class2 => @e, :object_relationship => @rp)
    @oEI = OntologyRelationship.create!(:ontology_class1 => @e, :ontology_class2 => @i, :object_relationship => @ri)
    @oCF = OntologyRelationship.create!(:ontology_class1 => @c, :ontology_class2 => @f, :object_relationship => @ri)
    @oCG = OntologyRelationship.create!(:ontology_class1 => @c, :ontology_class2 => @g, :object_relationship => @rp)
    @oFH = OntologyRelationship.create!(:ontology_class1 => @f, :ontology_class2 => @h, :object_relationship => @rp)

    # two (logical) redundancies

    @oAE = OntologyRelationship.create!(:ontology_class1 => @a, :ontology_class2 => @e, :object_relationship => @rp)
    @oAG = OntologyRelationship.create!(:ontology_class1 => @a, :ontology_class2 => @g, :object_relationship => @rp)
  end

end
