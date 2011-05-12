# == Schema Information
# Schema version: 20090930163041
#
# Table name: otus
#
#  id               :integer(4)      not null, primary key
#  taxon_name_id    :integer(4)
#  is_child         :boolean(1)
#  name             :string(255)
#  manuscript_name  :string(255)
#  matrix_name      :string(64)
#  parent_otu_id    :integer(4)
#  as_cited_in      :integer(4)
#  revision_history :text
#  iczn_group       :string(32)
#  syn_with_otu_id  :integer(4)
#  sensu            :string(255)
#  notes            :text
#  proj_id          :integer(4)      not null
#  creator_id       :integer(4)      not null
#  updator_id       :integer(4)      not null
#  updated_on       :timestamp       not null
#  created_on       :timestamp       not null
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class OtuTest < ActiveSupport::TestCase
  fixtures :otus, :contents, :taxon_names
  
  def setup
    $person_id = 10
    $proj_id = 11
    @otu = Otu.create!(:name => "foo")
  end

  def test_deletion_of_otu_syn_with_another_otu
    o = Otu.create!(:name => "one")
    os = Otu.create!(:name => "two", :syn_otu => o)
    o.reload
    os.reload
  
    assert_equal o.id, os.syn_otu.id
    assert_equal 1, o.immediate_child_synonymous_otus.size
    assert o.destroy
    os.reload
    assert_equal nil, os.syn_with_otu_id

    assert os.destroy
  end

  def test_otus_are_protected_from_editing_and_deletion_by_proj_security_callbacks
    assert_equal $proj_id, @otu.proj_id
    assert @otu.respond_to?(:proj)
    assert @otu.check_proj
    $old_proj_id = $proj_id
    $proj_id += 5
    @otu.name = "foobar"
    assert_raise(RuntimeError) {@otu.save}
    @otu.reload
    assert_equal "foo", @otu.name
    assert_raise(RuntimeError) {@otu.destroy}
    $proj_id = $old_proj_id
    @otu.name = "foobar"
    assert @otu.save
    @otu.reload
    assert_equal "foobar", @otu.name
    assert @otu.destroy
  end
  
  def test_creator_and_updator_are_set_correctly_by_magic_field_callbacks
    assert_equal $person_id, @otu.creator_id
    assert_equal $person_id, @otu.updator_id
    assert @otu.respond_to?(:creator)
    assert @otu.respond_to?(:updator)
    $person_id += 3
    @otu.name = "foobar"
    assert @otu.save
    assert_equal $person_id, @otu.updator_id
    assert_equal $person_id - 3, @otu.creator_id
  end

  def test_transfer_contents_to_otu
    @other_otu = Otu.create!(:name => "bar")  ## NOTE that create! bypassess the model validation

    # create some content types for our has_many
    content_types = []
    (1..10).each{|i| content_types[i] = ContentType.create!(:name => "foo#{i}")}

    # and some content
    content = []
    (1..10).each{|i| content[i] = Content.create!(:otu => @otu, :content_type => content_types[i], :text => "content #{i}")}

    assert_equal "content 1", content[1].text
    assert_equal 10, @otu.contents.size
    assert_equal 0, @other_otu.contents.size
    
    assert_equal false, @otu.transfer_content_to_otu(@otu)
    assert_equal 10, @otu.contents.size

    @otu.transfer_content_to_otu(@other_otu)

    @other_otu.contents.reload
    @otu.contents.reload

    assert_equal 0, @otu.contents.size
    assert_equal 10, @other_otu.contents.size
  end

  def test_specimens_most_recently_determined_as
    s = []
    o1 = Otu.create!(:name => 'foo')
    o2 = Otu.create!(:name => 'bar')
    (1..10).each do |i| s[i] = Specimen.create! end
    (1..5).each do |i| s[i].specimen_determinations << SpecimenDetermination.new(:otu => o1, :det_on => Time.now)  end
    (1..10).each do |i| s[i].specimen_determinations  << SpecimenDetermination.new(:otu => o2, :det_on => Time.parse("1928/1/1"))  end

    (1..10).each do |i| s[i].reload end

    assert_equal 5, o1.specimens.size
    assert_equal 10, o2.specimens.size
    assert_equal 5, o1.specimens_most_recently_determined_as.size
    assert_equal 5, o2.specimens_most_recently_determined_as.size
  end

  def test_markers_for_currently_determined_specimens
    o = Otu.create!(:name => 'foo')
    lat = 0.1232
    long = 45.232
    ce_yes = Ce.create!(:latitude => lat , :longitude => long)
    ce_no = Ce.create!(:verbatim_label => "Foo")

    s = []
    (1..5).each do |i| s[i] = Specimen.create!(:ce => ce_yes) end
    (6..10).each do |i| s[i] = Specimen.create!(:ce => ce_no) end # make sure we don't grab these
    (1..10).each do |i| s[i].specimen_determinations << SpecimenDetermination.new(:otu => o, :det_on => '2007')  end

    assert_equal 10, o.specimens.size
    assert_equal 5, o.markers_for_currently_determined_specimens.size
    o.markers_for_currently_determined_specimens.each do |m|
      assert_equal lat, m[:latitude]
      assert_equal long, m[:longitude]
    end
  end

  def test_otu_with_tags_can_be_deleted

    o = Otu.create!(:name => 'o')
    k = Keyword.create!(:keyword => "blah")
    t = Tag.create(:addressable_id => o.id, :addressable_type => 'Otu', :keyword => k)

    o.reload

    assert_equal 1, o.tags.size
    assert o.destroy
  end

  # TODO: move to ByTnDisplay::Test
  # there is another "display" class in Otu.rb, test that here (should likely move it to /lib) or a helper
  def test_ByTnDisplay_class
    # otu/taxon map looks like
    #
    # no parent tn (o1)
    # no parent tn (o2)
    # family (fam, o3)      section 0
    #   genus 1 (t1, o4)    section 1
    #     sp 1 (t2, o5)     section 2
    #     sp 2 (t3)     
    #   genus 2 (t4, o6)    section 3 
    #     sp 3 (t5, o7, o8) section 4
    #   genus 3 (t6)        section 5 
    #     <none>

    # create the test map
    @fam = TaxonName.find(1) # use the fixtures root (name is "Papa")
    
    @t1 = TaxonName.new(:name => 'Gone') 
    @t4 = TaxonName.new(:name => 'Gtwo') 
    @t6 = TaxonName.new(:name => 'Gthree') 
    [@t6, @t4, @t1].each do |t|
      t.iczn_group = 'genus'
      t.save
      t.set_parent(@fam)
    end

    # can't use new 2.1 create blocks because of odd set_parent behaviour we still have
    @t2 = TaxonName.new(:name => 'sone') # use the fixtures root (starts at family)
    @t3 = TaxonName.new(:name => 'stwo')
    @t5 = TaxonName.new(:name => 'sthree')

    parents = [@t4, @t1, @t1]
    [@t5, @t3, @t2].each_with_index do |t, i| 
      t.iczn_group = 'species'
      t.save
      t.set_parent(parents[i]) 
    end

    # the otus
    @o1, @o2, @o3, @o4, @o5, @o6, @o7, @o8 = Otu.create!(
      [{:name => "o1"},
       {:name => "o2"},
       {:taxon_name_id => @fam.id, :name => "o3"},
       {:taxon_name_id => @t1.id, :name => "o4"},
       {:taxon_name_id => @t2.id, :name => "o5"},
       {:taxon_name_id => @t4.id, :name => "o6"},
       {:taxon_name_id => @t5.id, :name => "o7"},
       {:taxon_name_id => @t5.id, :name => "o8"}]) 

    @otus = [@o1, @o2, @o3, @o4, @o5, @o6, @o7, @o8]
    # see that tests setup ok
    assert_equal @t1.id, @t2.parent_id

    @fam.reload

    @foo = ByTnDisplay.new(@fam, @otus)
   
    assert_equal 2, @foo.unplaced_items.size
    assert_equal [@o1, @o2], @foo.unplaced_items
    
    assert_equal 5, @foo.sections.size 
   
    assert_equal @o3, @foo.sections[0].items[0]
    assert_equal @o4, @foo.sections[1].items[0]
    assert_equal @o5, @foo.sections[2].items[0]

    assert_equal 2, @foo.sections[4].items.size
    assert_equal [@o7, @o8], @foo.sections[4].items
  end
  
  def test_all_synonymous_otus_will_not_recurse_endlessly_even_if_people_create_loops
    @otu2 = Otu.create!(:name => "bar")
    @otu.update_attribute(:syn_with_otu_id, @otu2.id)
    @otu2.update_attribute(:syn_with_otu_id, @otu.id)
    assert_nothing_raised { @otu.all_synonymous_otus }
    assert_equal([@otu2], @otu.all_synonymous_otus)
  end

  def test_publishable_contents
    @otu = Otu.create!(:name => "Foosaurusrex")
    @ct = ContentType.create!(:name => 'bedtimestory')
    @text = "It was a dark and stormy night.  Really, it was."
  
    assert_equal [], @otu.contents.that_are_publishable

    @content = Content.create!(:otu => @otu, :text => @text, :content_type => @ct)
    @otu.reload  
    assert_equal [@content], @otu.contents.that_are_publishable
    @otu.publish_all_content 

    @content.reload # update to get the pub_content_id
    @otu.reload # publishable_content should remain the same
    assert_equal [@content], @otu.contents.that_are_publishable
  
  end

end
