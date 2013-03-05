# a class which organizes Objects with a taxon_name_id into sets for use in display
# does *NOT* take into account visibility at present, assumes the whole heirarchy is present
# this is essentially the intersection of two trees

# SEE the OtuTest for a unit test.

class ByTnDisplay
  attr_accessor :sections, :unplaced_items

  # takes a TaxonName and an arry of objects that have a taxon_name_id
  def initialize(items = [])
    @unplaced_items = [] 
    @sections = []

    return true if items.size == 0

    # determine the unplaced items (i.e. those without a TaxonName)
    items.each do |i|
      if i.taxon_name_id.empty?
        @unplaced_items << i
      end
    end

    # have to do this outside the above loop or wonkiness ensues 
    @unplaced_items.each do |i| 
      items.delete(i)
    end
 
    # make use of the existing taxon_name heirarchy!! 
    items.sort!{|a, b| a.taxon_name.l <=> b.taxon_name.l}

    s = {} # internal tracking for building the sections, tn.id => a @section index

    # sort things into buckets if needed 
    items.each do |i| 
      if s.keys.include?(i.taxon_name_id)
        @sections[s[i.taxon_name_id]].items << i
      else
        sn = ByTnDisplay::Section.new(i.taxon_name)   # make a new section
        sn.items << i                                 # add the initial object to it
        s.update(i.taxon_name_id => (@sections.size)) # create an internal reference by taxon name
        @sections << sn
      end
    end
    return true
  end

  class ByTnDisplay::Section
    attr_reader :header, :items
    # header is a taxon_name
    def initialize(header)
      @header = header
      @items = []
    end
  end

end

