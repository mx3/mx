# == Schema Information
# Schema version: 20090930163041
#
# Table name: mxes
#
#  id               :integer(4)      not null, primary key
#  name             :string(255)
#  revision_history :text
#  notes            :text
#  web_description  :text
#  is_multikey      :boolean(1)
#  is_public        :boolean(1)
#  proj_id          :integer(4)      not null
#  creator_id       :integer(4)      not null
#  updator_id       :integer(4)      not null
#  updated_on       :timestamp       not null
#  created_on       :timestamp       not null
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require 'mx'

class MxTest < ActiveSupport::TestCase

  fixtures :mxes
  fixtures :chrs_mxes
  fixtures :chrs
  fixtures :chr_states
  fixtures :mxes_otus
  fixtures :otus
  fixtures :codings

  # multikey test fixtures overview (chrs x otus)
  #      15        16        17        18        19        20 
  #  6   10(12-1)  15(14-1)  20(16-1)  25(18-1)  30(20-1)  -
  #  7   11(12-1)  16(14-1)  21(16-1)  26(17-0)  31(19-0)  -
  #  8   12(12-1)  17(14-1)  22(15-0)  27(17-0)  32(20-1)  - 
  #  9   13(12-1)  18(13-0)  23(15-0)  28(17-0)  33(19-0)  -
  #  10  14(11-0)  19(13-0)  24(15-0)  29(17-0)  34(20-1)  -
  # coding_id(state_id 0 - absent, 1 - present)

  def setup
    $person_id = 1
    $proj_id = 1
    @mk = Mx.find(4) # the multikey test
  end

  def test_adjacent_cells
     chr_id = 17
     otu_id = 9
     assert_equal [17, 8], @mk.adjacent_cells(:otu_id => otu_id, :chr_id => chr_id)[:above]
     assert_equal [17, 10], @mk.adjacent_cells(:otu_id => otu_id, :chr_id => chr_id)[:below]
     assert_equal [16, 9], @mk.adjacent_cells(:otu_id => otu_id, :chr_id => chr_id)[:left]
     assert_equal [18, 9], @mk.adjacent_cells(:otu_id => otu_id, :chr_id => chr_id)[:right]
     chr_id = 15
     otu_id = 6
     assert_equal [15, 10], @mk.adjacent_cells( :otu_id => otu_id, :chr_id => chr_id)[:above]
     assert_equal [15,7], @mk.adjacent_cells(:otu_id => otu_id, :chr_id => chr_id)[:below]
     assert_equal [20, 6], @mk.adjacent_cells( :otu_id => otu_id, :chr_id => chr_id)[:left]
     assert_equal [16, 6], @mk.adjacent_cells( :otu_id => otu_id, :chr_id => chr_id)[:right]
     chr_id = 19
     otu_id = 10
     assert_equal [19, 9], @mk.adjacent_cells( :otu_id => otu_id, :chr_id => chr_id)[:above]
     assert_equal [19, 6], @mk.adjacent_cells( :otu_id => otu_id, :chr_id => chr_id)[:below]
     assert_equal [18, 10], @mk.adjacent_cells( :otu_id => otu_id, :chr_id => chr_id)[:left]
     assert_equal [20, 10], @mk.adjacent_cells( :otu_id => otu_id, :chr_id => chr_id)[:right]
  end

  def test_first_otu
    assert_equal 6, @mk.otus.first.id
  end

  def test_first_chr
    assert_equal 15, @mk.chrs.first.id
  end

  def test_polymorphic_cells_for_chr
    # make some cells polymorphic
    Coding.create!(:chr_id => 15, :otu_id => 6, :chr_state_id => 11, :chr_state_state => "0")
    Coding.create!(:chr_id => 15, :otu_id => 10, :chr_state_id => 12, :chr_state_state => "1")
    @mk.reload
    foo = @mk.polymorphic_cells_for_chr(:chr => Chr.find(15), :symbol_start => 0)
    assert_equal 2, foo.size
    assert_equal [11,12], foo[0]
    assert_equal [11,12], foo[1]
  end

  def test_otus_within_mx_range
    # range/position starts at 1
    assert_equal [Otu.find(7), Otu.find(8)], @mk.otus.within_mx_range(2,3)
  end

  def test_chrs_within_mx_range
    assert_equal [Chr.find(17), Chr.find(18)], @mk.chrs.within_mx_range(3,4)
  end

  def test_codings_in_grid
    grid = @mk.codings_in_grid(:otu_start => 1, :otu_end => 3, :chr_start => 2, :chr_end => 4)
    assert_equal Coding.find(15), grid[:grid][0][0][0]
    assert_equal Coding.find(21), grid[:grid][1][1][0]
    assert_equal Coding.find(27), grid[:grid][2][2][0]
  end

  def test_count
    assert_equal 4, Mx.count
  end

  def test_validate_states
    @m = Mx.find(4)
    assert_equal 1, @m.validate_states([11]).size
    assert_equal 0, @m.validate_states([1]).size    
  end

  def test_clone_otu_to_otu
      
  end

  # below test functions variously used primarily in multi-keys (but also elsewhere)  

  def test_name
    assert_equal 'multikey test', @mk.name
  end

  def test_total_chars
    assert_equal 6, @mk.chrs.size
  end

  def test_chr_states
    assert_equal 10, @mk.chr_states.size
  end

  def test_unique_chr_state_ids
    assert_equal 10, @mk.unique_chr_state_ids.size
    assert_equal [11, 12, 13, 14, 15, 16, 17, 18, 19, 20], @mk.unique_chr_state_ids # test against sort?
    # need a better test here
   end

  def test_total_otus
    assert_equal 5, @mk.otus.size
  end

  # NEEDS FURTHER TESTS, while both pass here mx.codings does not work, while mx.codings_old does 
  def test_total_codings
    assert_equal 25, @mk.codings.size
   # assert_equal 25, @mk.codings_old.size
   # assert_equal @mk.codings.size, @mk.codings_old.size
  end

  def test_all_chars
    # likely DEPRECATED after rewrite
    assert_equal Chr.find([15,16,17,18,19,20]).collect{|o| o.id}.sort, @mk.chrs.map(&:id).sort #.collect{|o| o.id}.sort
    # assert_equal Chr.find([15,16,17,18,19,20]), @mk.all_chrs_sorted # (only works when characters have a sort code) 
    # assert_equal @mk.all_chrs_sorted, @mk.all_chrs
  end

  def test_uncoded_chrs
    assert_equal 1, @mk.uncoded_chrs.size
    assert_equal Chr.find(20), @mk.uncoded_chrs[0]
  end

  # could be a better test
  def test_coded_chrs
    assert_equal 5, @mk.coded_chrs.count
  end

  def test_otus_with_any_chr_state_ids # likely unused ultimately
    assert_equal 5, @mk.otus_with_any_chr_state_ids([15,16,17,18,19]).size
    assert_equal 1, @mk.otus_with_any_chr_state_ids([11]).size
    assert_equal 2, @mk.otus_with_any_chr_state_ids([11, 18]).size
    # invert tests
    assert_equal 4, @mk.otus_with_any_chr_state_ids([11], true).size
    assert_equal 3, @mk.otus_with_any_chr_state_ids([11, 18], true).size
  end  

  def test_chrs_by_chr_state_ids
    #[ids],invert, check 
    assert_equal nil, @mk.chrs_by_chr_state_ids([1], false, true)
    assert_equal 1, @mk.chrs_by_chr_state_ids([11]).size
    assert_equal 3, @mk.chrs_by_chr_state_ids([15,16,17,18,19]).size
    assert_equal 3, @mk.chrs_by_chr_state_ids([15,16,17,18,19], true, false).size
  end  

  def test_otus_with_all_chr_state_ids
    assert_equal [], @mk.otus_with_all_chr_state_ids([1])
    assert_equal 1, @mk.otus_with_all_chr_state_ids([11]).size
    assert_equal 2, @mk.otus_with_all_chr_state_ids([13,15]).size
    assert_equal 1, @mk.otus_with_all_chr_state_ids([13,15,20]).size
    assert_equal Otu.find(10).id, @mk.otus_with_all_chr_state_ids([11])[0].id
  end 

  # not really a Mx test, but easier done here where fixtures all present
  def test_otu_states
    o = Otu.find(6)
    assert_equal 5, o.chr_states_by_mx(@mk.id).size
  end

  def test_otu_ids_with_all_chr_state_ids
     assert_equal [6, 7 , 8], @mk.otu_ids_with_all_chr_state_ids([14])
     assert_equal [9, 10], @mk.otu_ids_with_all_chr_state_ids([14], true)
  end
  

  # post revision tests
  
  def setup2
    @mx = Mx.create!(:name => 'foo')
  end

  def make_otu_group_with_3_otus
    @g = OtuGroup.create!(:name => 'foo')
    @o1 = Otu.create!(:name => '0')
    @o2 = Otu.create!(:name => '1')
    @o3 = Otu.create!(:name => '2')
    @g.add_otu(@o1)
    @g.add_otu(@o2)
    @g.add_otu(@o3)
    @g.reload
  end

  def make_chr_group_with_3_chrs
    @cg = ChrGroup.create!(:name => 'foo')
    @c1 = Chr.create!(:name => '0')
    @c2 = Chr.create!(:name => '1')
    @c3 = Chr.create!(:name => '2')
    @cg.add_chr(@c1)
    @cg.add_chr(@c2)
    @cg.add_chr(@c3)
    @cg.reload
  end


  def test_setup2
    setup2
    assert_equal 0, @mx.chrs.count 
    assert_equal 0, @mx.otus.count 
    assert_equal 0, @mx.chrs_plus.count 
    assert_equal 0, @mx.otus_plus.count 
    assert_equal 0, @mx.chrs_minus.count 
    assert_equal 0, @mx.otus_minus.count 
    assert_equal 0, @mx.otu_groups.count 
    assert_equal 0, @mx.chr_groups.count 
  end

  def test_group_and_plus_otus
   setup2 
   make_otu_group_with_3_otus
   @mx.add_group(@g)
   assert_equal 3, @mx.otus.count  
   @mx.otus_plus << Otu.create!(:name => '4')
   @mx.otus_plus << Otu.create!(:name => '5')
   @mx.reload
   assert_equal 5, @mx.otus.count
   assert_equal 5, @mx.group_and_plus_otus.size 
  end

  def test_otus_from_groups
    setup2
    make_otu_group_with_3_otus
    @mx.add_group(@g)
    @mx.reload
    assert_equal 3, @mx.otus_from_groups.size
  end

  def test_chrs_from_groups
    setup2
    make_chr_group_with_3_chrs
    @mx.add_group(@cg)
    @mx.reload
    assert_equal 3, @mx.chrs_from_groups.size
  end

  def test_group_and_plus_chrs
   setup2 
   make_chr_group_with_3_chrs
   @mx.add_group(@cg)
   assert_equal 3, @mx.chrs.count
   @mx.chrs_plus << Chr.create!(:name => '4')
   @mx.chrs_plus << Chr.create!(:name => '5')
   @mx.reload
   assert_equal 5, @mx.chrs.count
   assert_equal 5, @mx.group_and_plus_chrs.size  
  end

  # adding an subtracting otus and chrs
  def test_adding_an_otu_plus_adds_to_matrix
    setup2
    assert_equal 0, @mx.otus_plus.count 
    o = Otu.create!(:name => 'foo')
    @mx.otus_plus << o
    @mx.reload

    # adds to the + list?
    assert_equal 1, @mx.otus_plus.count
    assert_equal o, @mx.otus_plus[0]

    # adds to the master list?
    assert_equal 1, @mx.otus.count
    assert_equal o, @mx.otus[0]
  end

  def test_removing_an_otu_plus_removes_from_matrix
    setup2
    assert_equal 0, @mx.otus_plus.count 
    o = Otu.create!(:name => 'foo')
    @mx.otus_plus << o
    @mx.reload

    assert_equal 1, @mx.otus_plus.count
    assert_equal o, @mx.otus_plus[0]
    @mx.remove_from_plus(o) # chains delete of plus and master list
    
    @mx.reload
    assert_equal 0, @mx.otus_plus.count
    assert_equal 0, @mx.otus.count
  end

  def test_removing_a_chr_plus_removes_from_matrix
    setup2
    assert_equal 0, @mx.chrs_plus.count 
    c = Chr.create!(:name => 'foo')
    @mx.chrs_plus << c
    @mx.save

    @mx.reload

    assert_equal 1, @mx.chrs_plus.count
    assert_equal c, @mx.chrs_plus[0]
    @mx.remove_from_plus(c) # chains delete of plus and master list
    
    @mx.reload
    assert_equal 0, @mx.chrs_plus.count
    assert_equal 0, @mx.chrs.count
  end

  def test_adding_an_otu_minus_subtracts_from_matrix
    setup2
    o = Otu.create!(:name => 'foo')
    @mx.otus_plus << o
    @mx.reload
    assert_equal 1, @mx.otus_plus.count 
    
    @mx.otus_minus << o
    @mx.reload
    assert_equal 1, @mx.otus_minus.count 
    
    assert_equal 0, @mx.otus.count
  end

  def test_removing_an_otu_minus_when_otherwise_present_adds_to_matrix
    setup2
    o = Otu.create!(:name => 'foo')
    @mx.otus_plus << o
    @mx.reload
    assert_equal 1, @mx.otus_plus.count 
    
    @mx.otus_minus << o
    @mx.reload
    assert_equal 1, @mx.otus_minus.count 
    assert_equal 0, @mx.otus.count
    @mx.remove_from_minus(o)
    @mx.reload
    assert_equal 0, @mx.otus_minus.count 
    assert_equal 1, @mx.otus.count
  end

  def test_adding_a_chr_plus_adds_to_matrix
    setup2
    c = Chr.create!(:name => 'foo')
    @mx.chrs_plus << c
    @mx.reload
    assert_equal 1, @mx.chrs_plus.count
    assert_equal c, @mx.chrs_plus[0]

    # adds to the master list?
    assert_equal 1, @mx.chrs.count
    assert_equal c, @mx.chrs[0]
  end

  def test_adding_a_chr_minus_subtracts_from_matrix
    setup2
    c = Chr.create!(:name => 'foo')
    @mx.chrs_plus << c
    @mx.reload
    assert_equal 1, @mx.chrs_plus.count
    assert_equal c, @mx.chrs_plus[0]

    @mx.chrs_minus << c
    @mx.reload
    assert_equal 1, @mx.chrs_minus.count
    assert_equal c, @mx.chrs_minus[0]

    assert_equal 0, @mx.chrs.count
  end

  def test_removing_a_chr_minus_adds_to_matrix_when_chr_otherwise_present
    setup2
    c = Chr.create!(:name => 'foo')
    @mx.chrs_plus << c
    @mx.reload
    assert_equal 1, @mx.chrs_plus.count
    assert_equal c, @mx.chrs_plus[0]

    @mx.chrs_minus << c
    @mx.reload
    assert_equal 1, @mx.chrs_minus.count
    assert_equal c, @mx.chrs_minus[0]
    assert_equal 0, @mx.chrs.count

    @mx.remove_from_minus(c)
    @mx.reload
    assert_equal 0, @mx.chrs_minus.count
    assert_equal 1, @mx.chrs.count
  end

  def test_adding_an_otu_group_adds_to_matrix
    setup2
    o = Otu.create!(:name => 'foo')
    o1 = Otu.create!(:name => 'bar')
    @og = OtuGroup.create!(:name => 'blorf')

    @og.otus << o
    @og.otus << o1
    @og.reload

    @mx.add_group(@og)
    @mx.reload

    assert_equal 2, @mx.otus.count
    
   # ordering ?
   # assert_equal o, @mx.otus[0]
   # assert_equal o1, @mx.otus[1]

  end

  def test_adding_a_chr_group_adds_to_matrix
    setup2
    o = Chr.create!(:name => 'foo')
    o1 = Chr.create!(:name => 'bar')
    @cg = ChrGroup.create!(:name => 'blorf')

    @cg.add_chr(o) # note that we CAN NOT do @cg.chrs << o
    @cg.add_chr(o1)
    @cg.reload

    @mx.add_group(@cg)
    @mx.reload

    assert_equal 1, @mx.chr_groups.count
    assert_equal 2, @mx.chrs.count
  end

  def test_adding_a_new_chr_to_chr_group_adds_to_matrix
    setup2
    make_chr_group_with_3_chrs
    @mx.add_group(@cg)
    @mx.reload

    assert_equal 3, @mx.chrs.count

    @c4 = Chr.create!(:name => 'meh')
    @cg.add_chr(@c4)

    @mx.reload
    assert_equal 4, @mx.chrs.count
    assert_equal [@c1.id, @c2.id, @c3.id, @c4.id], @mx.chrs.map(&:id)
  end

  def test_removing_a_chr_group_retains_chr_when_chr_plus
    setup2
    make_chr_group_with_3_chrs
    @mx.add_group(@cg)
    @mx.reload
    @mx.chrs_plus << @c1
    @mx.reload
    assert_equal 3, @mx.chrs.count
    assert_equal 1, @mx.chrs_plus.count
    @mx.remove_group(@cg)
    @mx.reload
    assert_equal 1, @mx.chrs.count
    assert_equal @c1, @mx.chrs.first
  end

  def test_removing_an_otu_group_retains_otu_when_otu_plus
    setup2
    make_otu_group_with_3_otus
    @mx.add_group(@g)
    @mx.reload
    @mx.otus_plus << @o1
    @mx.reload
    assert_equal 3, @mx.otus.count
    assert_equal 1, @mx.otus_plus.count
    @mx.remove_group(@g)
    @mx.reload
    assert_equal 1, @mx.otus.count
    assert_equal @o1, @mx.otus.first
  end

  def test_adding_a_new_otu_to_otu_group_adds_to_matrix
    setup2
    make_otu_group_with_3_otus
    @mx.add_group(@g)
    @g.reload

    assert_equal 3, @mx.otus.count
    assert_equal 3, @g.otus.count

    @o4 = Otu.create!(:name => 'meh')    
    @g.add_otu(@o4)

    assert_equal 4, @g.otus.count
    assert_equal 4, @mx.otus.count
  end

  def test_removing_an_otu_from_otu_group_removes_from_matrix_and_maintains_order
    setup2
    make_otu_group_with_3_otus
     
    @mx.add_group(@g)
    @mx.reload

    assert_equal 3, @mx.otus.count
    assert_equal ['0', '1', '2'], @mx.otus.map(&:name) 

    @g.remove_otu(@o2)  # NOTE WE CAN NOT DO otus.delete(@o1)
    @g.reload
    assert_equal 2, @g.otus.count

    @mx.reload
    assert_equal 2, @mx.otus.count
    assert_equal ['0', '2'], @mx.otus.map(&:name) 
    assert @mx.mxes_otus[1].move_higher
    
    @mx.reload
    assert_equal ['2', '0'], @mx.otus.map(&:name) 
  end

  def test_removing_a_chr_from_chr_group_removes_from_matrix
    setup2
    o = Chr.create!(:name => 'foo')
    o1 = Chr.create!(:name => 'bar')
    @cg = ChrGroup.create!(:name => 'blorf')

    @cg.add_chr(o)
    @cg.add_chr(o1)
    @cg.reload

    @mx.add_group(@cg)
    @mx.reload
    assert_equal 2, @mx.chrs.count
    @cg.remove_chr(o1)
    @cg.reload
    assert_equal 1, @cg.chrs.count
    @mx.reload
    assert_equal 1, @mx.chrs.count
  end


  def test_adding_an_otu_to_otu_grp_while_minus_otu_present_does_not_add_otu
    setup2
    make_otu_group_with_3_otus
    @mx.otus_minus << @o1 
    @mx.add_group(@g)
    @g.reload
    @mx.reload
    assert_equal 2, @mx.otus.count
    assert !@mx.otus.include?(@o1)
  end

  def test_adding_a_chr_to_chr_grp_while_chr_minus_does_not_add_chr
    setup2
    make_chr_group_with_3_chrs
    @mx.chrs_minus << @c1
    @mx.reload
    @mx.add_group(@cg)
    @cg.reload 
    @mx.reload
    assert_equal 2, @mx.chrs.count
    assert !@mx.chrs.include?(@c1)
  end

  def test_adding_a_chr_while_chr_minus_does_not_add_chr
    setup2
    make_chr_group_with_3_chrs
    @mx.chrs_minus << @c1
    @mx.reload
    @mx.chrs_plus << @c1
    @mx.reload
    assert_equal 1, @mx.chrs_minus.size
    assert_equal 1, @mx.chrs_plus.size
    assert_equal 0, @mx.chrs.size
  end

  def test_adding_an_otu_while_otu_minus_does_not_add_otu
    setup2
    make_otu_group_with_3_otus
    @mx.otus_minus << @o1
    @mx.reload
    @mx.otus_plus << @o1
    @mx.reload
    assert_equal 1, @mx.otus_minus.size
    assert_equal 1, @mx.otus_plus.size
    assert_equal 0, @mx.otus.size
  end

  def test_removing_a_otu_grp_while_otu_plus_does_not_remove_otu
    setup2
    make_otu_group_with_3_otus
    @mx.otus_plus << @o1
    @mx.reload
    @mx.add_group(@g)
    @mx.reload
    assert_equal 3, @mx.otus.size
    @mx.remove_group(@g)
    @mx.reload
    assert_equal @o1, @mx.otus.first
    assert_equal 1, @mx.otus.count
  end

  def test_removing_a_chr_grp_while_chr_plus_does_remove_add_otu
    setup2
    make_chr_group_with_3_chrs
    @mx.chrs_plus << @c1
    @mx.reload
    @mx.add_group(@cg)
    @mx.reload
    assert_equal 3, @mx.chrs.size
    @mx.remove_group(@cg)
    @mx.reload
    assert_equal @c1, @mx.chrs.first
    assert_equal 1, @mx.chrs.count
  end

  def test_adding_a_otu_plus_when_present_from_group_does_not_duplicate
    setup2
    make_otu_group_with_3_otus
    @mx.add_group(@g)
    @mx.reload
    @mx.otus_plus << @o1
    @mx.reload
    assert_equal 3, @mx.otus.size
    assert_equal @o1, @mx.otus.first
    assert_equal @o3, @mx.otus.last
  end

  def test_adding_a_chr_plus_when_present_from_group_does_not_duplicate
    setup2
    make_chr_group_with_3_chrs
    @mx.add_group(@cg)
    @mx.reload
    @mx.chrs_plus << @c1
    @mx.reload
    assert_equal 3, @mx.chrs.size
    assert_equal @c1, @mx.chrs.first
    assert_equal @c3, @mx.chrs.last
  end

  def test_adding_chr_minus_when_otherwise_empty_does_not_fail
    setup2
    make_chr_group_with_3_chrs
    @mx.chrs_minus << @c1
    @mx.reload
    assert_equal 1, @mx.chrs_minus.count
    assert_equal 0, @mx.chrs.count
  end

  def test_adding_otu_minus_when_otherwise_empty_does_not_fail
    setup2
    make_otu_group_with_3_otus
    @mx.otus_minus << @o1
    @mx.reload
    assert_equal 1, @mx.otus_minus.count
    assert_equal 0, @mx.otus.count
  end

  def test_destroying_an_otu_group_removes_otus_from_matrix_if_not_otherwise_present
    setup2
    make_otu_group_with_3_otus
    @mx.add_group(@g)
    @mx.reload
    assert_equal 3, @mx.otus.count
    @g.destroy
    @mx.reload
    assert_equal 0, @mx.otus.count
  end

  def test_destroying_a_chr_group_removes_chrs_from_matrix_if_not_otherwise_present
    setup2
    make_chr_group_with_3_chrs
    @mx.add_group(@cg)
    @mx.reload
    assert_equal 3, @mx.chrs.count
    @cg.destroy
    @mx.reload
    assert_equal 0, @mx.chrs.count
  end

  def test_destroy
    setup2
    make_otu_group_with_3_otus
    make_chr_group_with_3_chrs
    @mx.add_group(@g)
    @mx.add_group(@cg)
    @mx.otus_plus << Otu.create!(:name => 'foo')
    @mx.chrs_plus << Chr.create!(:name => 'foo')
    @mx.otus_minus << Otu.create!(:name => 'foo')
    @mx.chrs_minus << Chr.create!(:name => 'foo')
    @mx.reload
    assert_equal 4, @mx.chrs.count
    assert_equal 4, @mx.otus.count
    assert @mx.destroy
    assert_equal nil, MxesOtu.find_by_mx_id(@mx.id)
    assert_equal nil, ChrsMx.find_by_mx_id(@mx.id)
    assert_equal nil, MxesMinusChr.find_by_mx_id(@mx.id)
    assert_equal nil, MxesPlusChr.find_by_mx_id(@mx.id)
    assert_equal nil, MxesMinusOtu.find_by_mx_id(@mx.id)
    assert_equal nil, MxesPlusOtu.find_by_mx_id(@mx.id)
  end

  def tst_adding_tagged_otus_adds_otus_to_otu_plus_and_matrix
    assert flunk
  end

  def tst_adding_tagged_chrs_adds_chrs_to_chrs_plus_and_matrix
    assert flunk
  end

  ## viewing

  def test_slide_window_with_illegal_bounds_returns_false
    assert !@mk.slide_window(:otu_start => 0, :otu_end => 1, :chr_start => 15, :chr_end => 16, :x => 0, :y => 0) # bounds start at 1
  end

  def test_slide_window_nowhere_returns_same
    assert_equal 1,  @mk.slide_window(:otu_start => 1, :otu_end => 2, :chr_start => 1, :chr_end => 2, :x => 0, :y => 0)[:chr_start]
    assert_equal 1,  @mk.slide_window(:otu_start => 1, :otu_end => 2, :chr_start => 1, :chr_end => 2, :x => 0, :y => 0)[:otu_start]
  end

  def test_slide_window_in_x
    assert_equal 2,  @mk.slide_window(:otu_start => 1, :otu_end => 2, :chr_start => 1, :chr_end => 2, :x => 1, :y => 0)[:chr_start]
    assert_equal 3,  @mk.slide_window(:otu_start => 1, :otu_end => 2, :chr_start => 1, :chr_end => 2, :x => 1, :y => 0)[:chr_end]
  end

  def test_slide_window_in_x_hits_bounds
     assert_equal 5,  @mk.slide_window(:otu_start => 1, :otu_end => 1, :chr_start => 3, :chr_end => 4, :x => 4, :y => 0)[:chr_start]
     assert_equal 6,  @mk.slide_window(:otu_start => 1, :otu_end => 1, :chr_start => 4, :chr_end => 4, :x => 4, :y => 0)[:chr_end]
  end

  def test_slide_window_in_y
    assert_equal 2,  @mk.slide_window(:otu_start => 1, :otu_end => 2, :chr_start => 1, :chr_end => 2, :x => 0, :y => 1)[:otu_start]
    assert_equal 3,  @mk.slide_window(:otu_start => 1, :otu_end => 2, :chr_start => 1, :chr_end => 2, :x => 0, :y => 1)[:otu_end]
  end

  def test_slide_window_in_y_hits_bounds
    assert_equal 4,  @mk.slide_window(:otu_start => 3, :otu_end => 4, :chr_start => 1, :chr_end => 2, :x => 0, :y => 3)[:otu_start]
    assert_equal 5,  @mk.slide_window(:otu_start => 3, :otu_end => 4, :chr_start => 1, :chr_end => 2, :x => 0, :y => 3)[:otu_end]
  end

  def test_slide_window_works_diagonally
    assert_equal 3, @mk.slide_window(:otu_start => 2, :otu_end => 4, :chr_start => 1, :chr_end => 3, :x => 2, :y => 2)[:otu_start]
    assert_equal 5, @mk.slide_window(:otu_start => 2, :otu_end => 4, :chr_start => 1, :chr_end => 3, :x => 2, :y => 2)[:otu_end]
    assert_equal 3, @mk.slide_window(:otu_start => 2, :otu_end => 4, :chr_start => 1, :chr_end => 3, :x => 2, :y => 2)[:chr_start]
    assert_equal 5, @mk.slide_window(:otu_start => 2, :otu_end => 4, :chr_start => 1, :chr_end => 3, :x => 2, :y => 2)[:chr_end]
  end

  def test_slide_window_works_with_negative_x
    assert_equal 1, @mk.slide_window(:otu_start => 3, :otu_end => 4, :chr_start => 3, :chr_end => 4, :x => -2, :y => 0)[:chr_start]
    assert_equal 2, @mk.slide_window(:otu_start => 3, :otu_end => 4, :chr_start => 3, :chr_end => 4, :x => -2, :y => 0)[:chr_end]
   
    assert_equal 1, @mk.slide_window(:otu_start => 3, :otu_end => 4, :chr_start => 3, :chr_end => 5, :x => -5, :y => 0)[:chr_start]
    
    assert_equal 3, @mk.slide_window(:otu_start => 3, :otu_end => 4, :chr_start => 3, :chr_end => 5, :x => -6, :y => 0)[:chr_end]
  end

  def test_slide_window_works_with_negative_y
    assert_equal 1, @mk.slide_window(:otu_start => 3, :otu_end => 4, :chr_start => 3, :chr_end => 4, :y => -2, :x => 0)[:otu_start]
    assert_equal 2, @mk.slide_window(:otu_start => 3, :otu_end => 4, :chr_start => 3, :chr_end => 4, :y => -2, :x => 0)[:otu_end]

    assert_equal 1, @mk.slide_window(:otu_start => 3, :otu_end => 4, :chr_start => 3, :chr_end => 5, :y => -5, :x => 0)[:otu_start]
    assert_equal 2, @mk.slide_window(:otu_start => 3, :otu_end => 4, :chr_start => 3, :chr_end => 5, :y => -5, :x => 0)[:otu_end]
  end

  def test_slide_window_converts_strings_to_ints
    assert_equal 1, @mk.slide_window(:otu_start => "3", :otu_end => "4", :chr_start => "3", :chr_end => "5", :y => "-5", :x => "0")[:otu_start]
  end

  def test_slide_window_works_with_codings_in_grid
    grid = @mk.codings_in_grid(@mk.slide_window(:otu_start => 3, :otu_end => 4, :chr_start => 3, :chr_end => 5, :y => -5, :x => 0))
   assert_equal Coding.find(20), grid[:grid][0][0][0]
    assert_equal Coding.find(21), grid[:grid][0][1][0]
  end
  
  def test_slide_window_always_returns_a_fully_dimensioned_grid

    foo = @mk.slide_window(:otu_start => 1, :otu_end => 2, :chr_start => 1, :chr_end => 2, :y => 10, :x => 10)
    assert_equal 5, foo[:chr_start]
    assert_equal 6, foo[:chr_end]
    assert_equal 4, foo[:otu_start]
    assert_equal 5, foo[:otu_end]

   foo = @mk.slide_window(:otu_start => 2, :otu_end => 4, :chr_start => 2, :chr_end => 4, :y => -10, :x => -10)
   assert_equal 1, foo[:chr_start]
    
   assert_equal 3, foo[:chr_end]
   
   assert_equal 1, foo[:otu_start]
   assert_equal 3, foo[:otu_end]
  end

  ## other functions
  def test_codings_by_xy
    assert_equal Coding.find(18), @mk.codings_by_xy(1,3)[0]
  end

  def test_codings_by_xy2
   # assert_equal 23, @mk.codings_by_xy(2,3)[0].id
   # assert_equal 10, @mk.codings_by_xy()[0].id # default to 0,0
   # assert_equal false, @mk.codings_by_xy(29, 123)
   # assert_equal 30, @mk.codings_by_xy(4, 0)[0].id
  end


  def test_reset_chr_positions
    assert @mk.reset_chr_positions
  end

  def test_reset_otu_positions
    assert @mk.reset_otu_positions
  end

  

end
