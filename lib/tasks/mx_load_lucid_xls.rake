require 'tempfile'
# require 'csv'

$USAGE = 'Call like: rake mx:load_lucid_xls matrix_name=Foo_name project=12 person=2 file=lucid.csv RAILS_ENV=development' 

# reads a very simply formatted file in Lucid's xls format (not verified)
# originally used for a one-off load 

# the file is of the form

# <blank>, otu1, otu2, otu3 ... otu_n
# Character group:character name: character state, state, state, ... state
# Character group:character name: character state, state, state, ... state
# ...
# Character group:character name: character state, state, state, ... state

namespace :mx do
  desc $USAGE
  task :load_lucid_xls => [:environment, :project, :person] do
 
   @file = ENV['file']

   if !@file || !ENV['matrix_name'] 
     puts "ERROR " + $USAGE
     abort # might be better way to do this
   end

    m = get_csv(@file)
    
    otus = m.shift
    otus.shift # first column is nothing

    @new_otus = [] 

    begin
      Mx.transaction do
        # create the Otus
        otus.each do |r|
          o = Otu.new(:name => r)
          o.save
          @new_otus << o 
        end
      end
   
      # create the characters
      @chr_groups = {}
      @chrs = {}

      print "\nCoding: "

      m.each do |r|
        tmp = r.shift
        tmp.gsub!(/^"(.*?)"$/,'\1')
        cd = tmp.split(":") # get the character data, strip the quotes if they are there

        # Wallace labels
        chr_lbl = "#{cd[0]}:#{cd[1]}" # the label we'll use

        raise "\ndied on #{tmp}, doesn't have 2 colons\n" if cd.size != 3

        if @chr_groups[cd[0].to_sym] # character group for this character exists
          @chr_grp = @chr_groups[cd[0].to_sym] 
        else
          @chr_grp = ChrGroup.create!(:name => cd[0])
          @chr_groups.merge!(@chr_grp.name.to_sym => @chr_grp)  # add it to a hash for future reference 
        end

        if @chrs[chr_lbl] # character exists
         @chr = @chrs[chr_lbl] 
        else
         @chr = Chr.create!(:name => chr_lbl)
         @chr_grp.add_chr(@chr)
         @chrs.merge!(chr_lbl => @chr) # add it to a has for future reference

         # uncomment to add a missing state
         # make sure there is a missing state for this chr
         # @cs_missing = ChrState.new(:name => 'missing', :state => "?")
         # @chr.chr_states <<  @cs_missing
         
         @chr.save
        end

        if @chr.chr_states.collect{|cs| cs.name}.include?(cd[2]) # character state exists
          raise "State '#{cd[2]}' is repeated for #{@chr.display_name}" # this should never happen, each line is a unique state 
        else
         @cs = ChrState.new(:name => cd[2], :state => @chr.chr_states.count.to_s) 
         @chr.chr_states << @cs
         @chr.save 
        end

        # we now have a @chr, @cs, and @chr_group, code the states 
        r.each_with_index do |cell,i|
          print "#{cell} "
          case cell.to_i
          when 0
            # do nothing
          when 1
            # code a cell
            # puts "coded #{@new_otus[i].id} / #{@chr.id} / #{@cs.id}\n"
            coding = Coding.new(:otu_id => @new_otus[i].id, :chr_id => @chr.id, :chr_state_id => @cs.id)
            coding.save
          when 3
            # uncomment to explicitly code  
            # coding = Coding.new(:otu_id => @new_otus[i].id, :chr_id => @chr.id, :chr_state_id => @cs_missing.id)
            # coding.save 
            # code a cell as missing
          else # nothing else is legal here
            raise 
          end
        end
      end
     puts " ... Done. \n"
      # everything is coded now, create and populate the matrix with characters/otus 
      @mx = Mx.new(:name => ENV['matrix_name'])
      @mx.save

      # add characters via character groups
      @chr_groups.keys.each do |k|
        @mx.add_group(@chr_groups[k])
      end

      # add otus
      @new_otus.each do |k|
        @mx.otus_plus << k
      end

    rescue
      raise # "Aborted! All changes rolled back."
    end

   puts "\nCharacter groups created: #{@chr_groups.values.collect{|cg| cg.display_name}.join(", ")}\n"
   puts "\nOtus created: #{@new_otus.collect{|o| o.display_name}.join(", ")}\n"
   puts "\n\nApparent success!\n" 

  end # end task
end # end namespace

