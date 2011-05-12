# == Schema Information
# Schema version: 20090930163041
#
# Table name: otu_groups
#
#  id         :integer(4)      not null, primary key
#  name       :string(64)
#  is_public  :boolean(1)
#  proj_id    :integer(4)      not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class OtuGroupTest < ActiveSupport::TestCase
#  fixtures :otus, :contents, :taxon_names
  
  def setup
    set_before_filter_vars
    @og = OtuGroup.create!(:name => 'foo') 
  end

  def test_adding_a_non_otu_to_otu_group_fails
   assert !@og.add_otu(Chr.create!(:name => 'foo'))
  end
  
  def test_add_otus
   
    # note the use of Otu_group.add_otu instead of OtuGroup.otus << Otu
    # this is because
    # 1) habtm_acts_as_list (and acts_as_list in general) sucks,
    # and 2) we have to sync Otu groups with matrices
    # on addition and deletion of Otus
    
    @og.add_otu(Otu.create!(:name => 'one'))
    @og.reload
    assert_equal 1, @og.otus.count
    @og.add_otu(Otu.create!(:name => 'two'))
    @og.reload 
    assert_equal 2, @og.otus.count
    assert_equal 'one', @og.otus[0].name
    assert_equal 'two', @og.otus[1].name
  end

  def test_otus_in_otu_group_act_as_list_through_otu_groups_otus
    # yes moving the Otus through a otu_groups_otus model is ugly, but it WORKS
    # and it doesn't get incredibly confusing as when acts_as_habtm is invoked
    # plus we need to sync with matrices- trust me, this is easiest
    
    o1 = Otu.create!(:name => 'one')
    o2 = Otu.create!(:name => 'two')
    o3 = Otu.create!(:name => 'three')
    @og.add_otu(o1) # see note above on .add_otu vs. <<
    @og.add_otu(o2)
    @og.add_otu(o3)
    @og.reload 
    assert_equal 3, @og.otus.count

   assert_equal 'one', @og.otu_groups_otus[1].higher_item.otu.name
   assert_equal 'three', @og.otu_groups_otus[1].lower_item.otu.name
     
   @og.otu_groups_otus[0].move_lower
   assert_equal 'two', @og.otus[0].name
  end

  def test_remove_otu
    o1 = Otu.create!(:name => 'one')
    o2 = Otu.create!(:name => 'two')
    o3 = Otu.create!(:name => 'three')
    @og.add_otu(o1) # see note above on .add_otu vs. <<
    @og.add_otu(o2)
    @og.add_otu(o3)
    @og.reload 
    assert_equal 3, @og.otus.count
  
    @og.remove_otu(o2) # same logic as .add_otu, don't use .delete!!
    @og.reload
    assert_equal 2, @og.otus.count
    assert_equal o1, @og.otus[0]
    assert_equal o3, @og.otus[1]  
  end

  def test_otu_groups_otus_reposition_correctly
    @og.add_otu(Otu.create!(:name => '1')) # see note above on .add_otu vs. <<
    @og.add_otu(Otu.create!(:name => '2'))
    @og.add_otu(Otu.create!(:name => '3'))
    @og.add_otu(Otu.create!(:name => '4'))
    @og.reload 
    assert_equal 4, @og.otus.count

    assert @og.otu_groups_otus[3].move_to_top
    @og.reload # REQUIRED
    assert_equal ['4', '1', '2', '3'], @og.otus.collect{|o| o.name}
    
    assert @og.otu_groups_otus[1].move_higher
    @og.reload # REQUIRED
    assert_equal ['1', '4', '2', '3'], @og.otus.collect{|o| o.name}
    
    assert @og.otu_groups_otus[2].move_lower
    @og.reload # REQUIRED
    assert_equal ['1', '4', '3', '2'], @og.otus.collect{|o| o.name}
  end

end
