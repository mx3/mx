# not included in environment
# require 'breakpoint'
# call task like this::#rake mx:load_tree_genus_names file=/Users/Irene/Desktop/treehopper_test.csv person=13 project=67 RAILS_ENV=development

require 'tempfile'
require 'csv'

$USAGE = 'Call like: "rake mx:load_tree_genus_names file=/Users/Irene/Desktop/treehopper_test.csv start=0 end=9 person=34 project=67 RAILS_ENV=development"' 

# groups namespace mx:etc all in same block
=begin
  TODO i dont know what this is doing
=end
namespace :mx do
  desc $USAGE
  task :update_tree_auths => [:environment, :project, :person] do
    TaxonName.find_by_name("Membracoidea").full_set.each do |n|
      if n.author =~ /Homo\.|Syn\.|Emend\./
        foo = n.author.split
          n.notes = foo.pop
          n.year = foo.pop
          n.author = foo.join(" ")
          n.save
        puts "updated #{n.name} #{n.id} to author:[#{n.author}], year:[#{n.year}], notes:[#{n.notes}]"
      end  
    end
  end

  desc "upload taxon data for treehopper" # have to add desc to show in rake --tasks
  task :load_tree_genus_names => [:environment, :project, :person] do

    # 0 -Genus/Subgenus
    # 1 - secret Display
    # 2 - Genus (or subgenus) name
    # 3 - Author
    # 4 - Date
    # 5 - Letter suffix of date
    # 6 -  secret Page(s)
    # 7 - Original Reference 
    # 8 - Further References
    # 9 -Status   
    # 10 -Notes on status
    # 11 -Notes on placement
    # 12 - Species
    # 13 -Senior synonym (see valid genus) 
    # 14 -Cross-reference (see valid genus)
    # 15- superfamily 
    # 16 - Family
    # 17 - Subfamily    
    # 18 - Tribe

#these come from the command line
   @file = ENV['file']
   @start = ENV['start'].to_i
   @end = ENV['end'].to_i

   if !@file 
     puts "ERROR " + $USAGE
     abort # might be better way to do this
   end
 
   # auditing/error checking, not ultimately used for addition
   # create your arrays
   @superfamilies = [] 
   @families = [] 
   @subfamilies = []
   @tribes = []
   @genera = []


   @names_to_add = []
   names = get_csv(@file) # file comes from get
   names.shift # get rid of headers

   names.each do |n|

    parent = nil

    @superfamilies.push(n[15])
    @families.push(n[16])
    @tribes.push(n[18])
    @subfamilies.push(n[17])
    @genera.push(n[2])
    


=begin
  TODO dealing with the genus level; need to deal with other levels before and in order
=end

 if n[9] == 'valid'
   #will need to add more statements depending on which reason not valid because valid name occurs in diff columns
   date_letter = n[4] + n[5]
   name = n[2]
   author = n[3]
   notes = n[9]
   valid_name = n[2]
   parent = n[18]
     @names_to_add.push(Genus.new(:parent => parent, :name => name, :author => author, :year => date_letter, :valid_name => valid_name, :notes => notes))
 else
   if n[9] == 'junior homonym' || n[9] == 'junior synonym'
     name = n[2]
     valid_name = n[13]
     author = n[3]
     notes = n[9]
     parent = 'Membracoidea' #will update later, just adding under superfamily for now
     @names_to_add.push(Genus.new(:parent => parent, :name => name, :author => author, :year => date_letter, :valid_name => valid_name, :notes => notes))
  #not a valid name will update later
else
  puts n[9] + " need to deal with other instances"
end #end if
 end #end if
  end #end block
    
    puts "ALL NAMES:  (#{@names_to_add.size} total + 1)"
    @names_to_add.each do |n|
      puts [n.name, n.author, n.year, n.notes, n.valid_name].compact.join(" ") + " [#{n.parent}] " 
    end



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
# really dont need this part but we know all the author and years are there so doesnt hurt
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
                            :iczn_group => "genus", :parent_id => parent.id, :notes => n.notes},
            :person => person
          )
          log.puts "added: " + [n.name, n.author, n.year].compact.join(" ") + " [#{n.parent}] " + (n.valid_name ? " =#{n.valid_name}" : "") +  " [mxid: #{new_name.id}]"
        end
      end
  

      log.puts "\nupdating pointers to valid names:"
      # now do a pass to update names to valid names
      # QUICK AND DIRTY because we're string matching and we should be matching on objects (but hopefully few errors introduced here, it's generic names)
      @names_to_add[@range].each do |n|
        if n.valid_name != n.name
          if !valid_name = TaxonName.find(:first, :conditions => {:name => n.valid_name})
            log.puts "failed (no valid name found): " + [n.name, n.author, n.year].compact.join(" ") + " [#{n.parent}] " 
            next
          else
            tn = TaxonName.find(:first, :conditions => {:name => n.name})
            tn.valid_name_id = valid_name.id
            tn.save
            log.puts "valid name update: " + [n.name, n.author, n.date_letter].compact.join(" ") + " [#{n.parent}] " + (n.valid_name ? " =#{n.valid_name}" : "") + " [mx #{tn.id} => #{valid_name.id}]"
          end
        end 
      end

    end # end transaction

    log.puts "done with #{@range}\n\n"

    log.close
    puts "end: " + Time.now.to_s
  end # end task


  # def parent_path(valid_name)   
  #   #find tribe for the valid name.  
  #   if valid_name == @ge
  #     parent = n[18]
  #   end
  #   
  #   return parent
  # end


  class Genus
    attr_accessor :parent, :name, :author, :year, :valid_name, :notes
    def initialize(opts)
      opts.to_options!
      @parent = opts[:parent]
      @name = opts[:name]
      @author = opts[:author]
      @year = opts[:year]
      @valid_name = opts[:valid_name] 
      @notes = opts[:notes]
    end
  end

end # end namespace



