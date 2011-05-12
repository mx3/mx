class Multikey 

  #
  # Modify this code ONLY IN CONJUNCTION WITH UNIT TESTS.
  # 
  # A Multikey is essentially a  "cart" of ChrStates, stored as a session variable.
  # Only ids are managed within a Multikey object, partially because Multikeys are stored as a session variable, and "best-principles" state not to store instantiated AR objects in a session.
  # A Multikey is also useful as a meta-information gatherer for matrices, it is essentially a state-space.

  # The only methods affecting the internal values (besides initialization and display) 
  # are calls to add/remove chr_state_id.  These calls may be made indirectly (e.g. choose_otu) but chr_state space should 
  # not be altered othewise!! Do not change this approach!  

  # note that if foo = [1,2] and bar = [2,1,3] that (foo & bar) != (bar & foo) ##

  # Characters that are not used in codings are eliminated at initialization!

  attr_reader :ALL_STATES           # all the states in the matrix
  attr_reader :STATES_BY_OTU
  attr_reader :UNIQUE_STATES_BY_OTU # may eliminate this for speed
  attr_reader :FIGURES_BY_CHR       # actually all those figs attached to chr_states, but grouped here
  attr_reader :STATES_BY_CHR
  attr_reader :OTUS_BY_STATE
  attr_reader :CHRS_NOT_CODED 
  attr_reader :MX_ID

  # these are likely CONSTANTS, but mayhaps add method to alter in the future
  attr_reader :all_otus  # array of IDs
  attr_reader :all_chrs

  attr_reader :chosen_states      # the chosen states
  attr_reader :remaining_choices  # all remaining states possessed by remaining taxa

  attr_reader :otus_remaining   # otus that have been chosen
  attr_reader :otus_eliminated  # all otus - chosen otus

  attr_reader :chrs_remaining   # chrs that REMAIN to be chosen (its bass-ackwards vs. OTUs)
  attr_reader :chrs_eliminated  # chrs that HAVE BEEN eliminated explicitly or by default

  attr_reader :current_chr_group

  # these are for layout
  attr_reader :display_windows
  attr_reader :view # store the current frame we're looking at, 'default', 'compare'

  def initialize(mx_id) # called on creation
    #throw "multikey not initialized with a matrix" if not mx.class == Mx
    reset!(mx_id)
  end

  def reset!(mx_id)
    if mx = Mx.find(mx_id)
      if mx.chrs.size == 0 || mx.otus.size == 0
        raise "Matrix incomplete, either characters or otus unpopulated."
      end 
      else
      raise "Couldn't find that matrix during reset!" 
    end

    # these are fixed, or only updated rarely
    @ALL_STATES = mx.unique_chr_state_ids
    @MX_ID = mx.id
    @view = 'default'

    @current_chr_group = nil

    all_otus = mx.otus.collect{|o| o.id} # used 2x, save the query
    all_coded_chrs = mx.coded_chrs

    @all_otus = all_otus # maybe not needed

    # these need to be updated at each add/remove states
    @CHRS_NOT_CODED = [] # chars attached to mtrx with no states
    @CHRS_NOT_CODED = mx.uncoded_chrs.collect{|o| o.id}

    @otus_remaining = [] # this is all the OTUs that are still possible outcomes
    @otus_eliminated = [] # all_otus # at the begining everyting is eliminated

    @chrs_eliminated = [] # chrs that have been used already
    @chrs_remaining = all_coded_chrs.map(&:id) # chrs that haven't been used yet, AND that are still useful

    @chosen_states = []
    @remaining_choices = @ALL_STATES

    @STATES_BY_OTU = {} # build a hash of otu coding vectors here for fewer datatabase hits
    
    # TODO: should be limited to coded chrs 
    # TODO: should be 
    chr_state_ids = mx.chrs.inject([]) {|sum, c| sum + c.chr_states.collect{|o| o.id}}
    sql = "chr_state_id IN (#{chr_state_ids.join(",")})" # .inject([]){|s, o| s << "chr_state_id = #{o}"}.join(' OR ')
    
    for o in all_otus
      @STATES_BY_OTU[o] =  Coding.find(:all, :conditions => "(#{sql}) AND otu_id = #{o}").collect{|p| p.chr_state_id} 
    end

    @UNIQUE_STATES_BY_OTU = {}
    for o in @all_otus
      @UNIQUE_STATES_BY_OTU[o] =  @all_otus.inject(@STATES_BY_OTU[o]){|sum, p| sum - (p != o ? @STATES_BY_OTU[p] : [])} 
    end

    # experimental, for visual cues
    @OTUS_BY_STATE = {}
    for o in @ALL_STATES
      @OTUS_BY_STATE[o] = mx.otu_ids_with_all_chr_state_ids([o])
    end

    @STATES_BY_CHR = {}
    @FIGURES_BY_CHR = {}
    for o in all_coded_chrs
      @STATES_BY_CHR[o.id.to_i] = o.chr_states.collect{|p| p.id}
      @FIGURES_BY_CHR[o.id.to_i] = o.chr_states.inject([]){|s, q| s + q.figures.collect{|r| r.id.to_i} }
    end
    
    @all_chrs = @STATES_BY_CHR.keys

    # below involved in display/"pagination"
    @display_windows = {}
    @display_windows['otu_elim'] = {}
    @display_windows['otu_remn'] = {}
    @display_windows['chr_remn'] = {}
    @display_windows['chr_elim'] = {}
    @display_windows['otu_elim']['pos'] = 0
    @display_windows['otu_remn']['pos'] = 0
    @display_windows['chr_elim']['pos'] = 0
    @display_windows['chr_remn']['pos'] = 0
    @display_windows['otu_elim']['size'] = 20
    @display_windows['otu_remn']['size'] = 30
    @display_windows['chr_elim']['size'] = 5
    @display_windows['chr_remn']['size'] = 5
  end

  # public set methods

  # some accesors for external access (am I missing something as to why they aren't available outside?)

  def figures_by_chr(chr_id)
    @FIGURES_BY_CHR[chr_id.to_i]
  end

  def view
    @view
  end

  def remaining_choices
    @remaining_choices
  end

  # CHANGED THIS
  def otus_remaining
    @chosen_states.size == 0 ? @all_otus : @otus_remaining
  end

  # set methods
  def set_view(type)
    #return false if view != ('default' || 'compare' || 'chosen_figures')
    @view = type
  end

  def set_window_size(type, size) 
    size = 5 if size < 1
    @display_windows[type]['size'] = size
    true
  end

  def slide_window(type, direction)
    max = case type
    when 'otu_elim'
      self.otus_eliminated.size
    when 'otu_remn'
      self.otus_remaining.size
    when 'chr_elim'
      self.chrs_eliminated.size
    when 'chr_remn'
      self.chrs_remaining.size
    end

    if direction == 'up'
      if (@display_windows[type]['pos'] + 1) * @display_windows[type]['size'] >= max  # wraps
        @display_windows[type]['pos'] = 0
      else
        @display_windows[type]['pos'] += 1
      end
    elsif direction == 'down' 
      if  @display_windows[type]['pos'] == 0
        a = max % @display_windows[type]['size']
        b = (max / @display_windows[type]['size']) - 1 # ranges go from zero
        @display_windows[type]['pos'] = (a > 0 ? 1 : 0) + (b > 0 ? b : 0) # likely easier way to calc this        
      else
        @display_windows[type]['pos'] -= 1
      end
    end
    true
  end

  def set_current_chr_group(id)
    @current_chr_group = (id)
    true
  end

  # pass a [] of Ints
  def add_states(states)
    @chosen_states = ( @chosen_states | states  ) & @ALL_STATES # make sure the state set is a member of all_states (perhaps slow)
    update!
  end

  def remove_states(states)
    @chosen_states = ( @chosen_states - states ) & @ALL_STATES
    update!
  end

  def update!
    update_otus # otus must come first!
    update_chrs
    @remaining_choices = self.remaining_state_choices 
  end

  def update_otus
    @otus_remaining = []
    if @chosen_states == []
      @otus_remaining = @all_otus
    else  
      for o in @all_otus ## don't need to check this many on add (but remove we do) could optimize as such checking only otus_eliminated on add
        # order matters in & operations,  so we use size to compare 
        @otus_remaining.push(o) if (@STATES_BY_OTU[o] & @chosen_states).size == @chosen_states.size
      end  
    end
    @otus_eliminated = @all_otus - @otus_remaining
    true
  end

  # can definitely be optimized further
  def update_chrs
    @chrs_eliminated = []

    if @chosen_states == []
      @chrs_eliminated = [] # @all_chrs
      @chrs_remaining = @all_chrs
    else
      if @otus_remaining.size == 1
        @chrs_remaining = []
      else
        @chrs_remaining = useful_chrs #useful characters from otus remaining  ?
      end
      @chrs_eliminated = @all_chrs - @chrs_remaining    
    end
    true
  end

  # subset of remaining chrs that are found in remaining otus
  def useful_chrs 
    chrs = []
    # useful chars are:
    # chars not used that contain states of remaining taxa that have > 1 state
    states = @otus_remaining.inject([]){|sum, o| sum = sum | @STATES_BY_OTU[o]} # all remaining states possed by Otus

    for c in @all_chrs # can't be used, need to loop otus_remaining
      chrs.push(c) if (@STATES_BY_CHR[c] & states).size > 1
    end
    chrs.sort # not ultimately needed, but if removed breaks tests
  end

  # note that elminating an Otu/Chr eliminates a state space, so additional OTUs may also be eliminated
  # this has to be for the functionality of the key to remain simple (to program) 
  # add only those states that are PRESENTLY unique to the given OTU, thus eliminating it !!
  # if there are no unique states its impossible to eliminate the OTU!
  # not quite the same as just using UNIQUE_STATES_BY_OTU as it compares to presently remaining otus!
  def choose_otu(otu_id) # this essentially ends the key, as it picks unique states
    others = @otus_remaining - [otu_id]
    other_states = []
    add = []
    other_states = others.inject([]){|sum, o| sum = sum | (@STATES_BY_OTU[o])} # all remaining states
    add = (@STATES_BY_OTU[otu_id] - (@STATES_BY_OTU[otu_id] & other_states)) & (self.unchosen_states || [])

    add_states(add)
  end

  def return_otu(otu_id) # i.e. make it available for choice again - tricky, to return an OTU all states BUT those of the otu must be removed
    remove_states(@chosen_states - @STATES_BY_OTU[otu_id]) 
  end

  # not presently used
  def eliminate_chr(chr_id)
    add_states(@STATES_BY_CHR[chr_id])
  end

  def return_chr(chr_id)
    remove_states(@STATES_BY_CHR[chr_id])
  end

  def unchosen_states
    @ALL_STATES - @chosen_states
  end

  # only those choices that are possible, used to set @remaining_choices
  # Note  that this is not USEFUL characters, as uniformative states for characters that are not useful but 
  # not picked are also included
  def remaining_state_choices
    return @ALL_STATES if @chosen_states == []
    self.unchosen_states & @otus_remaining.inject([]){|sum, o| sum = sum | @STATES_BY_OTU[o]}
  end

  # below return Objects, not ids
  def remaining_otus(ids = self.otus_remaining[window('otu_remn')])
    return [] if ((self.otus_remaining == []) or (ids == []))
    Otu.find(ids, :include => [:mxes, :mxes_otus], :order => 'mxes_otus.position', :conditions => "mxes_otus.mx_id = #{@MX_ID}")
  end

  def eliminated_otus(ids = self.otus_eliminated[window('otu_elim')])
    return [] if ((self.otus_eliminated == []) or (ids == []))
    Otu.find(ids, :include => [:mxes, :mxes_otus], :order => 'mxes_otus.position', :conditions => "mxes_otus.mx_id = #{@MX_ID}")
  end

  def eliminated_chrs(ids = self.chrs_eliminated[window('chr_elim')]) # if any state from a chr is picked the chr is "eliminated" (i.e. no longer pickable)
    return [] if ((self.chrs_eliminated == []) or (ids == []) or (ids == nil))
    Chr.find(ids, :include => [:mxes, :chrs_mxes], :order => 'chrs_mxes.position', :conditions => "chrs_mxes.mx_id = #{@MX_ID}")
  end

  def remaining_chrs(ids = self.chrs_remaining[window('chr_remn')]) 
    return [] if ((self.chrs_remaining == []) || (ids == []) || (ids == nil)) ## shouldn't need ids == nill here or above
    Chr.find(ids, :include => [:mxes, :chrs_mxes], :order => 'chrs_mxes.position', :conditions => "chrs_mxes.mx_id = #{@MX_ID}")
  end

  def remaining_otus_by_state(state_id)
    Otu.find(self.otus_remaining.inject([]){|sum, o|  sum + ((@STATES_BY_OTU[o] & [state_id.to_i]).size > 0 ? [o] : []) })
  end

  def remaining_states_by_otu(otu_id)
    ChrState.find(@STATES_BY_OTU[otu_id] | @chosen_states)
  end

  def chosen_figures
    sql = self.chosen_states.inject([]) {|sum, c| sum << "addressable_id = #{c}"}.join(' OR ')
    if sql.size > 0
       Figure.find(:all, :conditions => sql)
    else
       nil
    end  
  end
 
  def remaining_figures
     sql = self.remaining_state_choices.inject([]) {|sum, c| sum << "addressable_id = #{c}"}.join(' OR ')
    if sql.size > 0
      Figure.find(:all, :conditions => sql)
    else
      nil
    end
  end

  def all_tags
    tags = []
    tags <<  @all_otus.inject([]) {|sum, o| sum +  Otu.find(o).public_tags}
    tags <<  @ALL_STATES.inject([]) {|sum, o| sum +  ChrState.find(o).public_tags }
    tags <<  @all_chrs.inject([]) {|sum, o| sum + Chr.find(o).public_tags }
    # codings ... 
    tags.flatten.group_by{|o| o.keyword}
  end
  
  def remaining_tags
    tags = []
    tags <<  @otus_remaining.inject([]) {|sum, o| sum +  Otu.find(o).public_tags}
    tags <<  @remaining_choices.inject([]) {|sum, o| sum +  ChrState.find(o).public_tags }
    tags <<  @chrs_remaining.inject([]) {|sum, o| sum + Chr.find(o).public_tags }
    # codings ... 
    tags.flatten.group_by{|o| o.keyword}
  end
  
  # returns a Range of inidices to extract from an array, or nil
  def window(win_type)
    w = (@display_windows[win_type]['pos'] * @display_windows[win_type]['size'])..(((@display_windows[win_type]['pos'] + 1) * @display_windows[win_type]['size']) - 1)
    # kludge to truncate window on over-wrapping  
    if (win_type == 'otu_elim') || (win_type == 'otu_remn')
      b = w.to_a & (0..(@all_otus.size - 1)).to_a
      b.first..b.last 
    elsif (win_type == 'chr_elim') || (win_type == 'chr_remn')
      b = w.to_a & (0..(@all_chrs.size - 1)).to_a
      b.first..b.last  
    else
      raise 'passed an illegal type to multikey.window'
    end
  end

end

