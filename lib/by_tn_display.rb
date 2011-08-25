# a class which organizes Objects with a taxon_name_id into sets for use in display
# does *NOT* take into account visibility at present, assumes the whole heirarchy is present
# this is essentially the intersection of two trees

# SEE the OtuTest for a unit test.

class ByTnDisplay
  attr_accessor :sections, :unplaced_items

  # takes a TaxonName and an arry of objects that have a taxon_name_id
  def initialize(root_at_taxon_name, items = [])
    @tn = root_at_taxon_name # the root name, DEPRECATED
    @items = items
    @unplaced_items = [] 
    @sections = []

    return true if @items.size == 0

    # grab the unplaced items
    @items.each do |i|
      if i.taxon_name_id == nil
        @unplaced_items << i
      end
    end
  
    # have to do this outside the above loop or wonkiness ensues 
    @unplaced_items.each do |i| 
      # TODO mx3 - this is deleting records now! (v. bad)
      @items.delete(i)
    end

    # make use of the existing taxon_name heirarchy!! 
    @items.sort!{|a, b| a.taxon_name.l <=> b.taxon_name.l}

    # hmm @items.first is the smallest l, but what's the largest r? (replace below)
    # if root_at_taxon_name is not provided find the smallest inclusive root 
    if @tn.nil?
      min_l = nil 
      max_r = -1
      @items.each do |i|
        min_l = i.taxon_name.l if min_l == nil || i.taxon_name.l < min_l
        max_r = i.taxon_name.r if i.taxon_name.l > max_r 
      end
      @tn = TaxonName.find(:all, :conditions => ["l < ? AND r > ?", min_l, max_r], :order => "l DESC", :include => [{:parent => :parent}, {:ref => :authors}]).first
    end

    # TODO: we don't actually need a root now!
    @root_taxon_name = @tn

    s = {} # internal tracking for building the sections, tn.id => a @section index

    # sort things into buckets if needed 
    @items.each do |i| 
      if s.keys.include?(i.taxon_name_id)
        @sections[s[i.taxon_name_id]].items << i
      else
        sn = ByTnDisplay::Section.new(i.taxon_name)   # make a new section
        sn.items << i                                 # add the initial object to it
        s.update(i.taxon_name_id => (@sections.size)) # create an internal reference by taxon name
        @sections << sn
      end
    end
  end

  class Section
    attr_reader :header, :items
    # header is a taxon_name
    def initialize(header)
      @header = header
      @items = []
    end
  end

end

