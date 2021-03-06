
# ===============================================================================#
# = for special characters: 1. save from excel as .csv, 2. open in textwrangler= # 
# = 3. change to utf8, windows line endings                                    = #
# ===============================================================================#

require 'tempfile'
require 'csv'

$USAGE = 'Call like: "rake mx:load_tree_higher_names file=/Users/Irene/Desktop/highergroups3.csv start=0 end=400 person=34 project=22 rank=Class RAILS_ENV=development"' 



namespace :mx do
  desc $USAGE
  task :load_tree_higher_names => [:environment, :project, :person] do

    # 0 - Heirarchy
    # 1 - Rank : put in notes
    # 2 - Name 
    # 3 - Author
    # 4 - Date
    # 5 - Suffex date letter, ref table in mx
    # 6 - Page : page_first_appearance
    # 7 - Original reference, will add later 
    # 8 - Parent
    # 9 - Status   
    # 10 -Note on Status, add to notes
    
    #neeed to add import_notes, display_name


   @file = ENV['file']
   @start = ENV['start'].to_i
   @end = ENV['end'].to_i
   @rank = ENV['rank'].to_s
   

   if !@file 
     puts "ERROR " + $USAGE
     abort # might be better way to do this
   end
 
   # auditing/error checking, not ultimately used for addition
   @name = [] 
   @parent = []

   @names_to_add = []
   names = get_csv(@file)
   names.shift # get rid of headers

   names.each do |n|

    parent = nil

    @name.push(n[2])
    @parent.push(n[8])
    parent = n[1]  # always present
    
    # ===========================================================================#
    # = go through all the ranks in order; manually change status;             = #
    # = do valid than invalid names                                            = # 
    # = have to start with the valid names first then go through invalid names = #
    # ===========================================================================#

    if n[1] == @rank && n[9] == 'valid'
    #if n[1] == @rank && n[9] != 'valid'
     if @rank == 'Genus'
        group = 'Genus'
      else
        if @rank == 'Family'
        group = 'Family'
      else
        group = 'n/a'
      end
    end

       year = n[4]
       name = n[2]
       author = n[3]
       parent = n[8]
       notes = "rank:" + n[1]
       page_validated_on = n[6]
       import_notes = 'treehopper data, Lewis Deitz data, ks import'

       if n[10] != nil
         notes = "rank:" + n[1] + ", " + "status:"+ n[10]
       end
       
  if n[9] == 'valid'
    valid_name = n[2]
         @names_to_add.push(Higher.new(:parent => parent, :name => name, :author => author, :year => year, :valid_name => valid_name, :notes => notes, :page_validated_on => page_validated_on, :import_notes => import_notes, :group => group))

  else # for names that are not valid
    if n[6] == 'unavailable'
      page_first_appearance = n[6] && page_validated_on == nil
    else
      page_validated_on = n[6]
    end
      valid_name = n[8]
         @names_to_add.push(Higher.new(:parent => parent, :name => name, :author => author, :year => year, :valid_name => valid_name, :notes => notes, :page_validated_on => page_validated_on, :page_first_appearance => page_first_appearance, :import_notes => import_notes, :group => group))
     
     end #end valid false
   end #end valid true
end
        puts "ALL NAMES:  (#{@names_to_add.size} total)"
        @names_to_add.each do |n|
          puts [n.name, n.author, n.year, n.notes, n.valid_name, n.notes, n.page_validated_on, n.import_notes].compact.join(" ") + " [#{n.parent}] " 

  end
   # ===========================================================================#
   # = change the rank here to go through all the ranks in order;             = # 
   # = ---------------------------------------------------------------------- = #
   # ===========================================================================#


   raise if !person = Person.find($person_id)

   puts "start: " + Time.now.to_s

   @range = (@start..@end) # going to do these in small batches

   log = File.new("log_#{@start}-#{@end}.txt", "w+")

   log.puts "\n\n\nLoading names from range: #{@start}-#{@end}."

    TaxonName.transaction do
      @names_to_add[@range].each do |n|
        if !parent = TaxonName.find(:first, :conditions => {:name => n.parent})
          log.puts "failed (no parent found): " + [n.name, n.author, n.year].compact.join(" ") + " [#{n.parent}] " 
          next
        end

        if new_name = TaxonName.find(:first, :conditions => {:name => n.name})
          if new_name.parent.name == n.parent       # update the author year
            new_name.author = n.author
            new_name.year = n.year
            new_name.save
            log.puts "updated with author/year: " + [n.name, n.author, n.year].compact.join(" ") + " [#{n.parent}] " + (n.valid_name ? " =#{n.valid_name}" : "") +  " [mxid: #{new_name.id}]"
          end
        else


          new_name = TaxonName.create_new(
            :taxon_name => {:name => n.name, :author => n.author, :year => n.year,
                            :iczn_group => n.group, :parent_id => parent.id, :notes => n.notes, :page_validated_on => n.page_validated_on, :import_notes => n.import_notes},
            :person => person
          )
          log.puts "added: " + [n.name, n.author, n.year].compact.join(" ") + " [#{n.parent}] " + (n.valid_name ? " =#{n.valid_name}" : "") +  " [mxid: #{new_name.id}]" + @rank
        end

      end


      log.puts "\nupdating pointers to valid names:"
      # now do a pass to update names to valid names for names that entered as not valid.  This field is NULL in valid names!
      @names_to_add[@range].each do |n|
        if n.valid_name != n.name
          if !valid_name = TaxonName.find(:first, :conditions => {:name => n.valid_name})
            log.puts "failed (no valid name found): " + [n.name, n.author, n.year].compact.join(" ") + " [#{n.parent}] " 
            next
          else
            tn = TaxonName.find(:first, :conditions => {:name => n.name})
            tn.valid_name_id = valid_name.id
            tn.save
            log.puts "valid name update: " + [n.name, n.author, n.year].compact.join(" ") + " [#{n.parent}] " + (n.valid_name ? " =#{n.valid_name}" : "") + " [mx #{tn.id} => #{valid_name.id}]"
          end
        end 
      end
      
    
    log.puts "\nupdating pointers to parents:"
    # now do a pass to update names to valid names
    # QUICK AND DIRTY because we're string matching and we should be matching on objects (but hopefully few errors introduced here, it's generic names)
    @names_to_add[@range].each do |n|
        if "#{n.valid_name}" == "#{n.parent}"
          if !pn = TaxonName.find(:first, :conditions => {:name => n.valid_name})
          next
         else
            tn = TaxonName.find(:first, :conditions => {:name => n.name})
            tn.parent = pn.parent
            tn.save
            log.puts "valid name update: " + [n.name, n.author, n.year].compact.join(" ") + (n.valid_name ? " =#{n.valid_name}" : "") + " [mx #{tn.parent_id} => #{pn.parent_id}]"
          end
        end
      end


    end # end transaction

    log.puts "done with #{@range}\n\n"

    log.close
    puts "end: " + Time.now.to_s

  end # end task


  # get the name, author and year from a string
  def name_author_year(string)
   s = string.split
   name = s.shift
   notes = nil
   notes ||= s.pop if s[-1] == ("Emend." || "Syn." || "Homo." || "check")
   year = nil
   year ||= s.pop if (s[-1] =~ /\A\d+\Z/ && s[-1].length == 4)
   authors = nil
   authors = s.join(" ") if s.size > 0
   [name, authors, year, notes]
  end

    class Higher
      attr_accessor :parent, :name, :author, :year, :valid_name, :notes, :group, :page_first_appearance, :import_notes, :page_validated_on
      def initialize(opts)
        opts.to_options!
        @parent = opts[:parent]
        @name = opts[:name]
        @author = opts[:author]
        @year = opts[:year]
        @valid_name = opts[:valid_name] 
        @notes = opts[:notes]
        @group = opts[:group]
        @page_validated_on = opts[:page_validated_on]
        @import_notes = opts[:import_notes]
        @page_first_appearance = opts[:page_first_appearance]
      end #end initialize
    end #end class
  end #end namespace



