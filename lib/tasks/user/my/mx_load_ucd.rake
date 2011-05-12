# not included in environment
# require 'breakpoint'
require 'tempfile'
require 'csv'

$USAGE = 'Call like: "rake mx:load_cnc file=<full path> RAILS_ENV=production"' 

namespace :mx do
  desc $USAGE
  
  task :update_ucd_auths => [:environment, :project, :person] do
    TaxonName.find_by_name("Chalcidoidea").full_set.each do |n|
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

  task :load_ucd_genus_names => [:environment, :project, :person] do

   # the input file was generated from the xsl (Jan. 09) from Heraty like so:
    # in excel, save as->tab delimited
    # open in VIM, find/replace:
    # "," with "COMMA" (15 subs, these are apparently triple authors/name)
    # <tab> with ","
    # "COMMA" with ","
    # the ^K character with TAB (using GUI)
    # "TAB" with \t (1840) substitutions
    
    # 0 -superfamily
    # 1 - family
    # 2 - subfamily
    # 3 - genus
    # 4 - genus and synonyms


   @file = ENV['file']
   @start = ENV['s'].to_i
   @end = ENV['e'].to_i

   if !@file 
     puts "ERROR " + $USAGE
     abort # might be better way to do this
   end
 
   # auditing/error checking, not ultimately used for addition
   @superfamilies = []
   @families = []
   @subfamilies = []
   @tribes = []
   @genera = []

   tribes = {} 

   @names_to_add = []
   names = get_csv(@file)
   names.shift # get rid of headers

   names.each do |n|

    parent = nil

    @superfamilies.push(n[0])
    @families.push(n[1])
    parent = n[1]  # always present

    # handle subfamily names
    if n[2]
      subfams = n[2].split
      case subfams.size
      when 1
        sf = subfams[0]
        parent = sf
        if sf  =~ /idae\Z/
          raise "#{n[2]} shouldn't be a family level name (idae) but is" 
        elsif sf =~ /inae\Z/
          @subfamilies.push(sf) 
        elsif sf =~ /ini\Z/
          puts "a tribe in subfamily: #{n[2]}"
          @tribes.push(sf)

        end
      when 2

        # puts "SOMETHING WITH 2: #{n[2]}"

        first = subfams.shift
        @subfamilies.push(first) 

        second = subfams.shift
        @tribes.push(second)
        parent = second
      
        tribes.update(second => first)

      else
        raise "MORE THAN 3 levels in subfamily column #{n}"
      end
    end
    
    # as a test
    @genera.push(n[3])

    valid_name = n[3]
    # genera in synonymy
   
    if n[4]
      n[4].split(/\t/).each do |g|
        nay = name_author_year(g)
        @names_to_add.push(Genus.new(:parent => parent, :name => nay[0], :author => nay[1], :year => nay[2], :valid_name => valid_name, :notes => nay[3]))
      end
    else
      puts "#{n} doesn't have a synonym list"
    end

   end

  # parent name author year valid
  # puts @superfamilies.uniq.sort.join(", ")
  # puts @families.uniq.sort.join("\n")
  # puts @subfamilies.uniq.sort.join("\n")
  # puts @tribes.uniq.sort.join(", ")
  
  #tribes.keys.each do |t|
  #  puts "#{t} -> #{tribes[t]}\n"
  #end

  # puts @names_to_add

    puts "ALL NAMES:  (#{@names_to_add.size} total)"
    @names_to_add.each do |n|
      puts [n.name, n.author, n.year].compact.join(" ") + " [#{n.parent}] " 
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
            log.puts "valid name update: " + [n.name, n.author, n.year].compact.join(" ") + " [#{n.parent}] " + (n.valid_name ? " =#{n.valid_name}" : "") + " [mx #{tn.id} => #{valid_name.id}]"
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



