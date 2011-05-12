# == Schema Information
# Schema version: 20090930163041
#
# Table name: chr_groups
#
#  id              :integer(4)      not null, primary key
#  name            :string(255)
#  notes           :text
#  position        :integer(4)
#  content_type_id :integer(4)
#  proj_id         :integer(4)      not null
#  creator_id      :integer(4)      not null
#  updator_id      :integer(4)      not null
#  updated_on      :timestamp       not null
#  created_on      :timestamp       not null
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class ChrGroupTest < ActiveSupport::TestCase
 
  # see OtuGroupTest for logic on why things are being done like this

  def setup
    set_before_filter_vars
    @cg = ChrGroup.create!(:name => 'foo') 
  end

  def test_adding_a_non_chr_to_chr_group_fails
   assert !@cg.add_chr(Otu.create!(:name => 'foo'))
  end
  
  def test_add_chrs
    @cg.add_chr(Chr.create!(:name => 'one'))
    @cg.reload
    assert_equal 1, @cg.chrs.count
    @cg.add_chr(Chr.create!(:name => 'two'))
    @cg.reload 
    assert_equal 2, @cg.chrs.count
    assert_equal 'one', @cg.chrs[0].name
    assert_equal 'two', @cg.chrs[1].name
  end

  def test_chrs_in_chr_group_act_as_list_through_chr_groups_chrs
    # yes moving the Chrs through a chr_groups_chrs model is ugly, but it works
    # and it doesn't get incredibly confusing as when acts_as_habtm is used
    # plus we need to sync with matrices
    
    o1 = Chr.create!(:name => 'one')
    o2 = Chr.create!(:name => 'two')
    o3 = Chr.create!(:name => 'three')
    @cg.add_chr(o1) # see note above on .add_chr vs. <<
    @cg.add_chr(o2)
    @cg.add_chr(o3)
    @cg.reload 
    assert_equal 3, @cg.chrs.count

   assert_equal 'one', @cg.chr_groups_chrs[1].higher_item.chr.name
   assert_equal 'three', @cg.chr_groups_chrs[1].lower_item.chr.name
     
   @cg.chr_groups_chrs[0].move_lower
   assert_equal 'two', @cg.chrs[0].name
  end

  def test_remove_chr
    o1 = Chr.create!(:name => 'one')
    o2 = Chr.create!(:name => 'two')
    o3 = Chr.create!(:name => 'three')
    @cg.add_chr(o1) # see note above on .add_chr vs. <<
    @cg.add_chr(o2)
    @cg.add_chr(o3)
    @cg.reload 
    assert_equal 3, @cg.chrs.count
  
    @cg.remove_chr(o2) # same logic as .add_chr, don't use .delete!!
    @cg.reload
    assert_equal 2, @cg.chrs.count
    assert_equal o1, @cg.chrs[0]
    assert_equal o3, @cg.chrs[1]  
  end

  def test_chr_groups_chrs_reposition_correctly
    @cg.add_chr(Chr.create!(:name => '1')) # see note above on .add_chr vs. <<
    @cg.add_chr(Chr.create!(:name => '2'))
    @cg.add_chr(Chr.create!(:name => '3'))
    @cg.add_chr(Chr.create!(:name => '4'))
    @cg.reload 
    assert_equal 4, @cg.chrs.count
    assert_equal ['1', '2', '3', '4'], @cg.chrs.map(&:name) 
    
    assert @cg.chr_groups_chrs[3].move_to_top
    @cg.reload # REQUIRED
    assert_equal ['4', '1', '2', '3'], @cg.chrs.map(&:name)
  
    assert @cg.chr_groups_chrs[1].move_to_bottom
    @cg.reload 
    assert_equal ['4', '2', '3', '1'], @cg.chrs.map(&:name)

    assert @cg.chr_groups_chrs[1].move_higher
    @cg.reload 
    assert_equal ['2', '4', '3', '1'], @cg.chrs.map(&:name)
    
    assert @cg.chr_groups_chrs[2].move_lower
    @cg.reload 
    assert_equal ['2', '4', '1', '3'], @cg.chrs.map(&:name)
  end

end
