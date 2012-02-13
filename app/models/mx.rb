# == Schema Information
#
# Table name: mxes
#
#  id               :integer(10)     not null, primary key
#  name             :string(255)     
#  revision_history :text            
#  notes            :text            
#  web_description  :text            
#  is_multikey      :boolean(1)      
#  is_public        :boolean(1)      
#  proj_id          :integer(10)     not null
#  creator_id       :integer(10)     not null
#  updator_id       :integer(10)     not null
#  updated_on       :timestamp       not null
#  created_on       :timestamp       not null

class Mx < ActiveRecord::Base
  has_standard_fields

  include ModelExtensions::Taggable
  include ModelExtensions::Figurable
  include ModelExtensions::DefaultNamedScopes 

  has_many :data_sources, :dependent => :nullify # can be used in multiple pubs etc.
  has_many :trees, :through => :data_sources

  has_many :mxes_otus, :dependent => :delete_all, :order => 'position', :include => :otu
  has_many :chrs_mxes, :dependent => :delete_all, :order => 'position', :include => :chr
  has_many :mxes_plus_chrs, :dependent => :delete_all
  has_many :mxes_plus_otus, :dependent => :delete_all
  has_many :mxes_minus_chrs, :dependent => :delete_all
  has_many :mxes_minus_otus, :dependent => :delete_all

  has_many :otus_minus, :through => :mxes_minus_otus, :source => :otu, :order => "otus.matrix_name, otus.name"
  has_many :otus_plus, :through => :mxes_plus_otus, :source => :otu, :order => "otus.matrix_name, otus.name"
  has_many :chrs_minus, :through => :mxes_minus_chrs, :source => :chr, :order => "chrs.name"
  has_many :chrs_plus, :through => :mxes_plus_chrs, :source => :chr, :order => "chrs.name"

  has_many :otus, :order => 'mxes_otus.position', :through => :mxes_otus, :source => :otu
  has_many :chrs, :order => 'chrs_mxes.position', :through => :chrs_mxes, :source => :chr
  has_many :chrs_by_name, :order => 'chrs.name', :through => :chrs_mxes, :source => :chr
  has_many :otus_by_name, :order => 'otus.matrix_name, otus.name', :through => :mxes_otus, :source => :otu

  has_and_belongs_to_many :chr_groups, :order => "chr_groups.name" # DON'T use Mx.otus_groups << OtuGroup, use Mx.add_group
  has_and_belongs_to_many :otu_groups, :order => "otu_groups.name"

  scope :with_otus, :conditions => "mxes.id in (Select m.id from mxes m right join mxes_otus mo on mo.mx_id = m.id)"
  scope :with_chrs, :conditions => "mxes.id in (Select m.id from mxes m right join chrs_mxes cm on cm.mx_id = m.id)"

  before_destroy :clear_groups 
  
  # need to validate matrix_name versus bad characters
  # this currently does not prevent duplicate names, because the proj_id is not set until save
  validates_uniqueness_of :name, :scope => :proj_id, :message => "A matrix of that name has already been created in this project."

  # adding and removing OTUs/Chrs should only be done with:
  #
  # remove_from_plus(obj)
  # remove_from_minus(obj)
  # 
  # add_group(group)
  # remove_group(group)
  # 
  # self.otus_plus << Otu
  # self.chrs_plus << Chr
  #
  # self.chrs_minus << Chr
  # self.otus_minus << Otu
  #
  # you CAN NOT do the following:
  # BAD self.otus << otu 
  # BAD self.chrs << chr 
  # BAD self.chrs_minus.destroy(Chr)
  # etc.

  def remove_from_plus(obj)
    @obj = obj 
    # destory triggers after_destroy filter  
    case obj.class.to_s
    when "Chr"
      @cm = MxesPlusChr.find_by_mx_id_and_chr_id(self.id, @obj.id) 
      @cm.destroy if @cm 
    when "Otu"
      om = MxesPlusOtu.find_by_mx_id_and_otu_id(self.id, @obj.id) 
      om.destroy if om 
    else
      return false
    end
    true
  end

  def remove_from_minus(obj)
    case obj.class.to_s
    when "Otu"
      om = MxesMinusOtu.find_by_mx_id_and_otu_id(self.id, obj.id) 
      om.destroy if om # triggers :before_destroy
    when "Chr"
      cm = MxesMinusChr.find_by_mx_id_and_chr_id(self.id, obj.id) 
      cm.destroy if cm  # triggers :before_destroy
    else
      return false
    end
    true
  end

  def add_group(group)
    case group.class.to_s
    when 'OtuGroup'
      group.mxes << self
      group.save
      otus_minus = self.otus_minus
      otus = self.otus
      group.otus.each do |o|
        if !otus.include?(o) && !otus_minus.include?(o)
          self.mxes_otus.create(:otu_id => o.id, :mx_id => self.id)
        end
      end
    when 'ChrGroup'
      group.mxes << self
      group.save
      chrs_minus = self.chrs_minus
      chrs = self.chrs
      group.chrs.each do |o|
        if !chrs.include?(o) && !chrs_minus.include?(o)
          self.chrs_mxes.create(:chr_id => o.id, :mx_id => self.id)
        end
      end
    else
      return false
    end
    self.save
  end

  def remove_group(group)
    case group.class.to_s
    when 'OtuGroup'
      otus_minus = self.otus_minus 
      otus_plus = self.otus_plus
      otus = self.otus
      group_otus = group.otus 
      self.otu_groups.delete(group) # remove from list 
      group_otus.each do |o|        # update master
        if !otus_plus.include?(o) || otus_minus.include?(o) # latter for redoing the sync
          self.otus.delete(o)
        end
      end
    when 'ChrGroup'
      chrs_minus = self.chrs_minus 
      chrs_plus = self.chrs_plus
      chrs = self.chrs
      group_chrs = group.chrs 
      self.chr_groups.delete(group) # remove from list 
      group_chrs.each do |o|        # update master
        if !chrs_plus.include?(o) || chrs_minus.include?(o) # latter for redoing the sync
          self.chrs.delete(o)
        end
      end
    else
      return false
    end
    self.save
  end

  # these can likely be optimized
  def group_and_plus_otus
    os = [] 
    os << self.otu_groups.inject([]) {|grp, o| grp << o.otus}
    os << self.otus_plus
    os.flatten.uniq
  end

  def group_and_plus_chrs
    cs = [] 
    cs << self.chr_groups.inject([]) {|grp, o| grp << o.chrs}
    cs << self.chrs_plus
    cs.flatten.uniq
  end

  def chrs_from_groups
    self.chr_groups.inject([]) {|grp, o| grp << o.chrs}.flatten.uniq
  end

  def otus_from_groups
    self.otu_groups.inject([]) {|grp, o| grp << o.otus}.flatten.uniq
  end

  def display_name(options = {})
    opt = {
      :type => :default}.merge!(options)
    s = ''
    case opt[:type]
    when :truncated
      s << name[0..25] + (name.size > 25 ? '...' : '')
    else
      s << name
    end
    s.html_safe
  end

  # Need this for select f(n) that can't pass params
  def truncated_name
    name[0..25] + (name.size > 25 ? '...' : '')
  end

  # return codings at the "position" x (chr), y (otu), could likely be done faster
  def codings_by_xy(x = 0, y = 0)
    c = self.chrs[x] # benchmarks must faster than self.chrs.find(:first, :offset => x) for some reason
    o = self.otus[y]
    return false if !c || !o
    Coding.find(:all, :conditions => {:otu_id => o.id, :chr_id => c.id})
  end

  # Returns an array of existing or new Coding objects
  def self.codings_for_code_form(options = {})
    opt = {
      :chr => nil,       # A Chr found like this: Chr.includes({:chr_states => :codings}).find(params[:chr_id]) 
      :otu => nil,       # An Otu 
      :ref => nil,       # A Ref 
      :confidence => nil # A Confidence 
    }.merge!(options)

    raise if opt[:chr].nil? || opt[:otu].nil?

    codings = []

    # Just find them, it's a single query
    codings_to_check = Coding.where(:otu_id => opt[:otu], :chr_id => opt[:chr])
    if opt[:chr].is_continuous? 
      if codings_to_check.size > 0  # There will be only one
        codings.push codings_to_check.first
      else
        codings.push Coding.new(:confidence => opt[:confidence], :ref => opt[:ref]) 
      end
    else
      opt[:chr].chr_states.each do |cs|
        found = false
        codings_to_check.each do |c|
          if cs.id == c.chr_state_id
            found = true
            codings.push c 
            break
          end
        end
        codings.push Coding.new(:confidence => opt[:confidence], :ref => opt[:ref]) if !found
      end
    end
    codings
  end



  # otus in the matrix sorted by name TODO: MOVE TO A NAMED SCOPE for OTUs :sorted_by_name
  def otus_by_name
    Otu.find_by_sql(["Select o.* from otus o right join mxes_otus on mxes_otus.otu_id = o.id where mx_id = ? ORDER BY o.matrix_name, o.name, o.manuscript_name, o.id;", self.id])
  end
 
  # all the codings in a matrix 
  def codings 
    Coding.in_matrix(self.id)
  end

  # used for codings_in_grid, returns bounds of a window offset by some left/right values
  # TODO: memomize this, including the mx_id
  def slide_window(options = {})
    @opts = {
      :otu_start => 1, # the starting points
      :otu_end => "all",
      :chr_start => 1,
      :chr_end => "all",
      :x => 0, # how far to slide the window, +/- values
      :y => 0
    }

    # TODO: need to convert values to Ints ... must be an easier way 
    @foo_opts = options.symbolize_keys # Rails method
    
    [:x, :y, :chr_start, :chr_end, :otu_start, :otu_end].each do |k|
      @foo_opts[k] = @foo_opts[k].to_i if !(@foo_opts[k] == 'all')
    end

    @opts.merge!(@foo_opts)
   
    return false if (@opts[:otu_start] <= 0 || @opts[:otu_end] <= 0 || @opts[:chr_start] <= 0 || @opts[:chr_end] <= 0 )
  
    @window = @opts.clone # default the values to opts, since we use symbols we have to clone    

    return @window if (@opts[:x] == 0) && (@opts[:y] == 0) # no sliding, just return what was passed

    if (@opts[:x] != 0) && (@opts[:chr_end] != 'all') # if 'all' then we can't slide in x
      x = self.chrs.count
      if (@opts[:x] + @opts[:chr_start] > 0) && ((@opts[:x] + @opts[:chr_end]) < x) # both within bounds
        @window[:chr_start] = @opts[:chr_start] + @opts[:x]
        @window[:chr_end] = @opts[:chr_end] + @opts[:x]
      elsif (@opts[:x] + @opts[:chr_start] < 0) && ((@opts[:x] + @opts[:chr_end]) < x) # hitting left bound
        @window[:chr_start] = 1 
        @window[:chr_end] = @opts[:chr_end] - @opts[:chr_start] + 1 # width of the window, starting from 1
      elsif (@opts[:x] + @opts[:chr_start] > 0) && (@opts[:x] + @opts[:chr_end] > x) # hitting right bound
        @window[:chr_start] = (x - (@opts[:chr_end] - @opts[:chr_start]))
        @window[:chr_end] = x
      end 
    end

    if (@opts[:y] != 0) && (@opts[:otu_end] != 'all') # if 'all' then we can't slide in y
      y = self.otus.count
      if (@opts[:y] + @opts[:otu_start] > 0) && (@opts[:y] + @opts[:otu_end] < y)
        @window[:otu_start] = @opts[:otu_start] + @opts[:y]
        @window[:otu_end] = @opts[:otu_end] + @opts[:y]
      elsif (@opts[:y] + @opts[:otu_start] < 0) && (@opts[:y] + @opts[:otu_end] < y) # hitting lower bound
        @window[:otu_start] = 1
        @window[:otu_end] = (@opts[:otu_end] - @opts[:otu_start]) + 1
      elsif  (@opts[:y] + @opts[:otu_start] > 0) && (@opts[:y] + @opts[:otu_end] > y) # hitting upper bound 
        @window[:otu_start] = (y - (@opts[:otu_end] - @opts[:otu_start]))
        @window[:otu_end] = y
      end 
    end

    return @window
  end

  # this could definitely be optimized
  # position is from 1 but grid is from 0 !!
  # optimize by 
  # - returning only codings within Otu range, not just Chr range
  def codings_in_grid(options = {})
    @opts = {
      :otu_start => 1,
      :otu_end => "all",
      :chr_start => 1,
      :chr_end => "all"
    }.merge!(options.symbolize_keys)

    return false if (@opts[:otu_start] == 0) || (@opts[:chr_start] == 0) # catch problems with forgetting index starts at 1

    otus = []  # y axis
    chrs = []  # x axis
    @o = []
    @c = []
    if @opts[:otu_end] == "all"
      @o = self.otus
      otus = @o.collect{|o| o.id}
    else
      @o = self.otus.within_mx_range(@opts[:otu_start], @opts[:otu_end])
      otus = @o.collect{|o| o.id}
    end

    return false if otus.size == 0

    if @opts[:chr_end] == "all"
      @c = self.chrs
      chrs = @c.collect{|o| o.id}
    else
      @c = self.chrs.within_mx_range(@opts[:chr_start], @opts[:chr_end])
      chrs = @c.collect{|c| c.id}
    end
    return false if chrs.size == 0

    # three dimensional array
    grid = Array.new(chrs.size){Array.new(otus.size){Array.new}}
    
    chrs.each do |chr|
      Coding.in_matrix(self).by_chr(chr).each do |c|
        if otus.index(c.otu_id)
          grid[chrs.index(c.chr_id)][otus.index(c.otu_id)].push(c) 
        end
      end
    end
    
    {:grid => grid, :chrs => @c, :otus => @o }
  end

  # likely should add scope and merge with above, though this seems to be slower 
  def codings_mx
    #  return a hash of hashes of arrays with the coding objects nicely organized
    #   chr_id1 =>{otu_id2 => [coding_obj, coding_obj], chr_id2 => nil}
    h = Hash.new{|hash, key| hash[key] = Hash.new{|hash2, key2| hash2[key2] = Array.new}} 
    codings.each {|c| h[c.chr_id][c.otu_id].push(c) }
    h
  end

  # takes :chr => Chr, :symbol_start => Int
  # returns a Hash of Int => Array
  # used as an index method for nexml output
  def polymorphic_cells_for_chr(options)
    @opt = {:symbol_start => 0}.merge!(options.to_options!)

    cells = Hash.new{|hash, key| hash[key] = Array.new}
    self.codings.by_chr(@opt[:chr]).each do |c|
      cells[c.otu_id].push(c.chr_state_id)
    end

    foo = Hash.new{|hash, key| hash[key] = Array.new}
    i = 0
    cells.keys.each do |k|
      if foo # must be some other idiom
        if cells[k].size > 1
          foo[@opt[:symbol_start] + i] = cells[k].sort 
          i += 1
        end
      end
    end
    foo
  end

  # returns {:direction => [otu_id, chr_id]} relative to current cell
  def adjacent_cells(options)
    @opts = {
      :otu_id => nil,
      :chr_id => nil,
    }.merge!(options.to_options!)

    # TODO: REDO- use position and > <
    # e.g. Chr.where(:id => ChrsMxes.where(position > chr.position).first) ...

    cells = {}
    return false if !@opts[:otu_id] && !@opts[:chr_id]
    x = self.chrs.index(Chr.find(@opts[:chr_id]))
    y = self.otus.index(Otu.find(@opts[:otu_id]))
   
    cells[:above] = [@opts[:chr_id], self.otus[y-1].id] 
    cells[:below] = [@opts[:chr_id], self.otus[(y == self.otus.count - 1 ? 0 : y+1)].id]  
    cells[:right] = [self.chrs[(x == self.chrs.count - 1 ? 0 : x+1)].id, @opts[:otu_id]]
    cells[:left] = [self.chrs[x-1].id, @opts[:otu_id] ]
    cells 
  end

  # all the characters currently uncoded in the matrix
  def uncoded_chrs 
    self.chrs.not_coded_in_matrix
  end

  # All Chrs in matrix that have been coded at least once
  def coded_chrs
    self.chrs.coded_in_matrix
  end

  # all ChrStates attached to Chrs in matrix 
  def chr_states
    self.chrs.inject([]) {|sum, chr| sum + chr.chr_states }
  end

  # all the unique chr state ids that have been used in this matrix, used in multikey cart, could be optimized
  def unique_chr_state_ids
    self.chrs.coded_in_matrix.inject([]) {|sum, c| sum + c.chr_states}.flatten.uniq.map(&:id) # maybe need a sort here 
  end

  # returns all the otus for the matrix that have ONE of the chr_state ids in [] (not a key function)
  # if invert == true then those OTUs not selected are returned
  def otus_with_any_chr_state_ids(ids, invert = false, check = false)
    return nil if ids.size == 0

    # verify that ids passed in fact belong to this matrix, and strike those that don't
    # defaults to off for speed
    if check == true
      ids = validate_states(ids)
    end

    otus = self.otus
    sql = "codings.chr_state_id IN (#{ids.join(",")})" # ids.inject([]){|sum, o| sum << "codings.chr_state_id = #{o}"}.join(' OR ')   # chr state conditions
    sql1 = "codings.otu_id IN (#{otus.map(&:id).join(",")})" # otus.inject([]){|sum, o| sum << "codings.otu_id = #{o.id}"}.join(' OR ')    # otus conditions
    
    found = Otu.find(:all, :include => [:codings], :conditions => "(#{sql}) AND (#{sql1})")   

    if invert == true
      return otus - found
    else
      return found
    end

  end


  # return only those OTUs with all chr state ids passed in the ids []
  ## might be doable in sql only, but I couldn't think of a way, mayhaps one pass in a union query
  def otus_with_all_chr_state_ids(ids, invert = false, check = false)
    return nil if ids.size == 0
    if check == true
      ids = validate_states(ids)
    end

    found = []
    # below can likely be spead up
    for o in self.otus
      found.push(o) if (ids & o.chr_states_by_mx(self.id)) == ids # a little set theory
    end

    if invert == true
      return self.otus - found
    else
      return found
    end

  end
  
  # as above, but returns only otu_ids, should be faster, and modifiable to return the otu
  def otu_ids_with_all_chr_state_ids(ids, invert = false, check = false)
    return nil if ids.size == 0
    if check == true
      ids = validate_states(ids)
    end

    sql = "chr_state_id IN (#{ids.join(",")})" # ids.inject([]){|sum, o| sum << "chr_state_id = #{o}"}.join(' OR ') 
    
    found = []
    found = Coding.find_by_sql([" Select DISTINCT otu_id from codings 
          INNER JOIN ( SELECT DISTINCT chr_id, mx_id from chrs_mxes) as j where mx_id = ? AND (#{sql});", self.id]).map(&:otu_id)

    if invert == true
      return self.otus.collect{|o| o.id} - found
    else
      return found
    end
  end
  
  def chrs_by_chr_state_ids(ids, invert = false, check = false)
    return nil if ids.size == 0

    # defaults to off for speed
    if check == true
      ids = validate_states(ids)
    end

    chrs = self.chrs
    found = Chr.by_states(ids)

    if invert == true
      return chrs - found
    else
      return found
    end

  end

  # show states in tnt or nexus format for a 'cell' (e.g. [ab]) 
  # presently used for nexus/tnt rendering
  def self.print_codings(codings, chr, otu, style = :tnt)
    case codings[chr.id][otu.id].size
    when 0
      "?"
    when 1
      v = codings[chr.id][otu.id][0].display_name(:type => :value)
      if v.to_s.length > 1 && style == :nexus
        "#{v} [WARNING STATE '#{v}' is TOO LARGE FOR PAUP (0-9, A-Z only).]"
      else
        v
      end
    else
      str = codings[chr.id][otu.id].collect{|c| c.display_name(:type => :value)}.sort.join("")
      if style == :nexus
        "{#{str}}"
      else
        "[#{str}]"
      end
    end
  end

  # Checks that an [] of chr_states belongs to the matrix, and returns only those that do
  def validate_states(ids)
    self.chr_states.collect{|o| o.id} & ids
  end

  # Reorders all characters in the matrix alphabetically by name
  def reset_chr_positions
    i = 1
    for o in ChrsMx.from_mx(self).ordered_by_chr_name
      o.position = i
      o.save
      i += 1
    end
    true
  end

  def reset_otu_positions
    i = 1
    # we have to call it this way to get the new ordering
    for o in MxesOtu.from_mx(self).ordered_by_otu_name
      o.position = i
      o.save
      i += 1
    end
    true
  end

  # returns a hash of hashes with the key a Character.id, and the value the percentage of states that character is coded for
  def percent_coded_by_chr
    h = {}
    otu_ids = self.otus.collect{|o| o.id}
    tot = self.otus.count
    for c in self.chrs
      h[c.id] = (tot == 0 ? 0 : (Otu.where(:id => Coding.where(:chr_id => c, :otu_id => otu_ids).collect{|i| i.otu_id})
.count.to_f / tot.to_f))
    end
    h
  end

  # returns a hash of hashes with the key a Otu.id, and the value the percentage of states that otu is coded for
  def percent_coded_by_otu
    h = {}
    tot = self.chrs.count
    for o in self.otus
      h[o.id] = (tot == 0 ? 0 : ( self.chrs_coded_by_otu_id(o.id).size.to_f / tot.to_f))
    end
    h
  end
  
  # returns Chrs coded by otu_id in this matrix # MOVE TO NAMED SCOPE in CHRS
  def chrs_coded_by_otu_id(otu_id)
    Chr.where(:id => Coding.where(:otu_id => otu_id, :chr_id => self.chrs).collect{|i| i.chr_id})
  end

  # returns Otus coded by chr_id in this matrix (NAMED SCOPE THIS)
  def otus_coded_by_chr_id(chr_id) 
    Otu.where(:id => Coding.where(:chr_id => chr_id, :otu_id => self.otus).collect{|i| i.otu_id})
  end

  # Handles incoming codings from MxController#code methods 
  # A little boolean logic lets us determine what to do 
  # Returns true or false
  #  params[:clicked] comes from one_click mode
  #  params[:checked] comes from the form itself
  def self.code_cell(params = {}) 
    # params.symbolize_keys!
    begin
      Coding.transaction do 
        params[:codings].keys.each do |k|
          # continuous?
          if !params[:codings][k][:continuous_state].blank? 
            if params[:codings][k][:id].blank? 
              c = Coding.new(params[:codings][k])
              c.save!
            else
              c = Coding.find(params[:coding][k][:id])
              params[:codings][k].delete(:id) # prevent mass assign warning 
              c.update_attributes(params[:codings][k]) 
            end
            # not continuous
          else 
            if params[:checked] && params[:checked][k] # checked 
              if params[:clicked] && params[:clicked][k] # checked & clicked (destroy)
                c = Coding.find(params[:codings][k][:id])
                c.destroy
                # break
              else # checked & !clicked (udpate/new)
                if !params[:codings][k][:id].blank?
                  c = Coding.find(params[:codings][k][:id])
                  params[:codings][k].delete(:id) # prevent mass assign warning 
                  c.update_attributes(params[:codings][k]) 
                else
                  c = Coding.new(params[:codings][k])
                  c.save!
                end
              end
            else # !checked
              if params[:clicked] && params[:clicked][k] #!checked & clicked (new)
                c = Coding.new(params[:codings][k])
                c.save!
                break
              else # !checked & !clicked & continuous_state.blank? (destroy when present)
                if params[:codings][k][:id]
                  c = Coding.find(params[:codings][k][:id])
                  c.destroy
                end
              end
            end
          end
        end
      end
    rescue
      raise 
    end
    true
  end

  def clone_to_simple # :yields: Mx (cloned, with OTU+, Chr+ only based on parent)
    mx = Mx.new(:name => "Simplified clone of #{self.name}")
    self.otus.each do |o|
      mx.otus_plus << o
    end
    self.chrs.each do |c|
      mx.chrs_plus << c
    end   
    mx.save
    mx 
  end

  def generate_chr_group # :yields: A ChrGroup containing self.chrs
    group = ChrGroup.new(:name => "Matrix derived from: #{self.name}")
    group.save!
    self.chrs.collect{|c| group.add_chr(c)}
    group
  end

  def generate_otu_group # :yields: An OtuGroup containing self.chrs
    group = OtuGroup.new(:name => "Matrix derived from: #{self.name}")
    group.save!
    self.otus.collect{|o| group.add_otu(o)}
    group 
  end
  
  def generate_concensus_otu # :yields: True || False
    # takes all non-continuous characters and builds a new OTU will codings for each represent coding, then adds that OTU to the matrix
    begin
      Mx.transaction do
        otu = Otu.new(:matrix_name => 'CONCENSUS_OTU', :name => 'Concensus OTU for matrix #{self.name}')
        otu.save!

        states_to_add = Coding.in_matrix(self.id).inject({}){|sum, c| sum.merge!(c.chr_state_id => c.chr)} # Build a hash of all unique states, only gets continuous values
        states_to_add.keys.each do |s|
          Coding.create!(:chr_state_id => s, :otu => otu, :chr => states_to_add[s])
        end

        self.otus_plus << otu
        self.save
      end
      true
    rescue
      raise # false
    end
  end

  def unused_chr_states # :yields: Array of ChrStates
    possible_chr_states - Coding.in_matrix(self.id).inject({}){|sum, c| sum.merge!(c.chr_state => c.chr)}.keys 
  end

  def possible_chr_states # :yields: Array of all possible ChrStates
    chrs.inject([]){|sum, c| sum << c.chr_states}.flatten
  end

  # TODO: RESOLVE WHERE THIS WAS USED CONFLICT
  def all_figures
    figures = [] 
    self.chr_states.each do |cs|
      figures += cs.figures
    end

    self.chrs.each do |c|
      figures += c.figures
    end

    self.codings.each do |c|
      figures += c.figures
    end

    figures.compact.uniq
  end

  private
 
  def clear_groups
    self.chr_groups.clear
    self.otu_groups.clear
  end


end
