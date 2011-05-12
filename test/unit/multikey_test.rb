require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class MultikeyTest < ActiveSupport::TestCase
  #  fixtures :people
  # fixtures :projs

  self.use_instantiated_fixtures  = true
  
  fixtures :mxes
  fixtures :chrs_mxes
  fixtures :chrs
  fixtures :chr_states
  fixtures :mxes_otus
  fixtures :otus
  fixtures :codings
  fixtures :chr_groups
  fixtures :chr_groups_chrs


  # multikey test fixtures overview (chrs x otus)
  #      15        16        17        18        19        20
  #  6   10(12-1)  15(14-1)  20(16-1)  25(18-1)  30(20-1)  no codings
  #  7   11(12-1)  16(14-1)  21(16-1)  26(17-0)  31(19-0)
  #  8   12(12-1)  17(14-1)  22(15-0)  27(17-0)  32(20-1)
  #  9   13(12-1)  18(13-0)  23(15-0)  28(17-0)  33(19-0)
  #  10  14(11-0)  19(13-0)  24(15-0)  29(17-0)  34(20-1)  
  # coding_id(state_id 0 - absent, 1 - present)

  def setup
    @mk = Multikey.new(4)
  end

  def test_init
    assert_equal 10, @mk.ALL_STATES.size
    assert_equal [6,7,8], @mk.OTUS_BY_STATE[14]
    assert_equal [8,9,10], @mk.OTUS_BY_STATE[15]
    assert_equal [7,9], @mk.OTUS_BY_STATE[19]
  end

  def test_states
    assert_equal [], @mk.chosen_states
    @mk.add_states([1, 2, 3, 4]) # none of these are legal states mx(4), thus none get added
    assert_equal 0, @mk.chosen_states.size 

    @mk.add_states([12,11])
    assert_equal 2, @mk.chosen_states.size

    @mk.remove_states([11])
    assert_equal 1, @mk.chosen_states.size
  end

  def test_add_remove_otu_chr_states
    o = Otu.find(10)
    assert_equal 1, o.unique_states.size
    @mk.add_states(o.unique_states)
    assert_equal 1, @mk.chosen_states.size
    o2 = Otu.find(6)
    @mk.add_states(o2.unique_states)
    assert_equal 2, @mk.chosen_states.size
    @mk.remove_states(o.unique_states)
    assert_equal 1, @mk.chosen_states.size
    o3 = Otu.find(8)
    @mk.add_states(o3.unique_states) # should add none
    assert_equal 1, @mk.chosen_states.size
  end

  def test_session_init
    assert_equal 5, @mk.STATES_BY_OTU[6].size
  end

  def test_chrs_not_coded
    assert_equal 20, @mk.CHRS_NOT_CODED[0]
  end

  def test_unique_states_by_otu
    assert_equal [18], @mk.UNIQUE_STATES_BY_OTU[6]
  end

  def test_choose_otu # 
    assert_equal 0, @mk.otus_eliminated.size
    @mk.choose_otu(10)
    assert_equal 1, @mk.otus_remaining.size
    assert_equal [15, 16, 17, 18, 19], @mk.eliminated_chrs.collect{|o| o.id}  # if an OTU is picked all characters should be eliminated
  end

  def test_remaining_state_choices
    assert_equal 10, @mk.remaining_state_choices.size
    assert_equal 10, @mk.remaining_choices.size
    @mk.add_states([12])
    assert_equal 8, @mk.remaining_state_choices.size
    @mk.add_states([16])
    assert_equal 5, @mk.remaining_state_choices.size # there is one constant character, but it is included
    assert_equal 5, @mk.remaining_choices.size # there is one constant character, but it is included
  end

  def test_remaining_otus
    assert_equal 5, @mk.otus_remaining.size # inverted when no states are chosen ALL remain
    @mk.add_states([12])
    assert_equal 4, @mk.otus_remaining.size
    @mk.add_states([14])
    assert_equal 3, @mk.otus_remaining.size
    @mk.add_states([16])
    assert_equal 2, @mk.otus_remaining.size
    @mk.add_states([19])
    assert_equal 1, @mk.otus_remaining.size
  end

  def test_eliminated_otus
    assert_equal 0, @mk.otus_eliminated.size
    @mk.add_states([12])
    assert_equal 1, @mk.otus_eliminated.size
    @mk.add_states([14])
    assert_equal 2, @mk.otus_eliminated.size
    @mk.add_states([16])
    assert_equal 3, @mk.otus_eliminated.size
    @mk.add_states([19])
    assert_equal 4, @mk.otus_eliminated.size
  end

  def test_eliminated_otus2 # tests the ordering of (foo & bar) = foo
    @mk.add_states([15])
    assert_equal 2, @mk.otus_eliminated.size
    @mk.add_states([13])
    assert_equal 3, @mk.otus_eliminated.size
    @mk.add_states([20])
    assert_equal 4, @mk.otus_eliminated.size
  end

  def test_work_key
    assert_equal 0, @mk.eliminated_chrs.size

    assert_equal 5, @mk.remaining_chrs.size # there are six - but only five have codings  

    assert_equal 5, @mk.otus_remaining.size # no states present, therefor all remain (cased out in Multikey)
    assert_equal 5, @mk.remaining_otus.size

    assert_equal 0, @mk.eliminated_otus.size
    assert_equal 0, @mk.otus_eliminated.size

    assert_equal 5, @mk.remaining_states_by_otu(6).size
    assert_equal [12,14,16,18,20], @mk.remaining_states_by_otu(6).collect{|o| o.id}

    @mk.add_states([11])
    assert_equal 1, @mk.remaining_otus.size
    @mk.remove_states([11])

    @mk.add_states([13, 15])
    assert_equal [13,15], @mk.chosen_states

    assert_equal 2, @mk.remaining_otus.size
    assert_equal [9,10], @mk.remaining_otus.collect{|o| o.id}

    assert_equal 3, @mk.eliminated_chrs.size # 13 and 15 are chosen - this eliminates the possibility of char 18 as well (as 6 is removed)
    assert_equal 3, @mk.chrs_eliminated.size
    assert_equal [16, 17, 18], @mk.eliminated_chrs.collect{|o| o.id}    
    assert_equal [16, 17, 18], @mk.eliminated_chrs.collect{|o| o.id}

    assert_equal 2, @mk.remaining_chrs.size
    assert_equal [15,19], @mk.remaining_chrs.collect{|o| o.id}

    assert_equal 1, @mk.remaining_otus_by_state(11).size
    assert_equal Otu.find(9), @mk.remaining_otus_by_state(19)[0]

    assert_equal [6,7,8], @mk.eliminated_otus.collect{|o| o.id}

    @mk.return_otu(6) # if 6 is to be possible then 13 or 15 can't be chosen! thus 7 and 8 are also returned
    assert_equal [], @mk.chosen_states
    assert_equal [6,7,8,9,10], @mk.remaining_otus.collect{|o| o.id}
    assert_equal [15,16,17,18,19], @mk.remaining_chrs.collect{|o| o.id}

    @mk.choose_otu(7) # 7 has no diagnostic characters, no states are chosen
    assert_equal [], @mk.chosen_states
  end

  def test_useful_chrs
    assert_equal 0, @mk.useful_chrs.size # the 'useful_chrs' are based on those taxa selected, no selected taxa, no "useful_chrs"
    @mk.add_states([15])
    assert_equal [15,16,19], @mk.useful_chrs
    assert_equal 3, @mk.useful_chrs.size
  end

  def test_visualize_key
    assert_equal 0, @mk.eliminated_chrs.size
    assert_equal 5, @mk.remaining_chrs.size # there are six - but only five have codings  
    assert_equal 5, @mk.remaining_otus.size # inverted when no states are chosen
    assert_equal 0, @mk.eliminated_otus.size

    assert_equal (0..4), @mk.window('chr_elim')
    assert_equal (0..4), @mk.window('otu_elim')

    @mk.set_window_size('chr_remn', 2)
    assert_equal 2, @mk.remaining_chrs.size
    assert_equal [15,16], @mk.remaining_chrs.collect{|o| o.id}

    @mk.set_window_size('otu_elim', 2)
    assert_equal 0, @mk.eliminated_otus.size
    assert_equal [], @mk.eliminated_otus.collect{|o| o.id}

    @mk.slide_window('otu_elim', 'up')
    assert_equal [], @mk.eliminated_otus.collect{|o| o.id}
  end

  def test_chrs_remaining
    assert_equal 5, @mk.chrs_remaining.size # all characters are available at the begining
    @mk.add_states([14]) # eliminates 2 characters, as 15 is no longer useful
    assert_equal 3, @mk.chrs_remaining.size 
    assert_equal [17,18,19], @mk.chrs_remaining
    @mk.add_states([17]) 
    assert_equal 2, @mk.chrs_remaining.size 
    assert_equal [17,19], @mk.chrs_remaining
    @mk.add_states([19])
    assert_equal [7], @mk.otus_remaining
    assert_equal 0, @mk.chrs_remaining.size 
  end

  def test_chrs_eliminated # a test of windows/wrapping/and more
    @mk.set_window_size('chr_elim', 2)
    assert_equal 0, @mk.display_windows['chr_elim']['pos']  
    assert_equal 0, @mk.eliminated_chrs.size

    @mk.slide_window('chr_elim', 'down') # shouldn't work
    assert_equal 0, @mk.display_windows['chr_elim']['pos']  

    @mk.add_states([12]) # eliminates 1 character

    assert_equal 1, @mk.eliminated_chrs.size

    @mk.slide_window('chr_elim', 'up')
    assert_equal 0, @mk.display_windows['chr_elim']['pos']  # can't go up with one chr eliminated
    assert_equal 1, @mk.eliminated_chrs.size

    @mk.add_states([14]) # eliminates a second character
    assert_equal 2, @mk.eliminated_chrs.size

    @mk.slide_window('chr_elim', 'up') # should do nothing
    assert_equal 0, @mk.display_windows['chr_elim']['pos']  

    @mk.slide_window('chr_elim', 'down') # should not wrap around, 2 chars are eliminated
    assert_equal 0, @mk.display_windows['chr_elim']['pos']  
    assert_equal 2, @mk.eliminated_chrs.size

    @mk.slide_window('chr_elim', 'down') # wraps around
    assert_equal 0, @mk.display_windows['chr_elim']['pos']  

    @mk.add_states([16])
    assert_equal 0, @mk.display_windows['chr_elim']['pos']  
    assert_equal 2, @mk.eliminated_chrs.size # really three, but with window 2

    @mk.slide_window('chr_elim', 'up')
    assert_equal 1, @mk.display_windows['chr_elim']['pos']  
    assert_equal 1, @mk.eliminated_chrs.size

    @mk.slide_window('chr_elim', 'down')
    assert_equal 0, @mk.display_windows['chr_elim']['pos']  
    assert_equal 2, @mk.eliminated_chrs.size        
  end


  def test_window
    @mk.set_window_size('chr_remn', 2)
    assert_equal 0, @mk.display_windows['chr_remn']['pos']  
    assert_equal [15,16], @mk.remaining_chrs.collect{|o| o.id}

    @mk.slide_window('chr_remn', 'up')
    assert_equal 1, @mk.display_windows['chr_remn']['pos']  
    assert_equal [17,18], @mk.remaining_chrs.collect{|o| o.id}

    @mk.slide_window('chr_remn', 'up')
    assert_equal 2, @mk.display_windows['chr_remn']['pos']  
    assert_equal 1, @mk.remaining_chrs.size # 5 characters, last one shows 
    assert_equal [19], @mk.remaining_chrs.collect{|o| o.id}

    @mk.slide_window('chr_remn', 'up')   # should wrap heres
    assert_equal 0, @mk.display_windows['chr_remn']['pos']  
    assert_equal 2, @mk.remaining_chrs.size 
    assert_equal [15,16], @mk.remaining_chrs.collect{|o| o.id}

    @mk.set_window_size('chr_remn', 4)

    @mk.slide_window('chr_remn', 'up')   # should wrap here
    assert_equal 1, @mk.display_windows['chr_remn']['pos']
    assert_equal 1, @mk.remaining_chrs.size

    assert_equal [19], @mk.remaining_chrs.collect{|o| o.id}

    @mk.set_window_size('chr_remn', 2)
    @mk.display_windows['chr_remn']['pos'] = 0
    @mk.slide_window('chr_remn', 'down') 
  end

end
