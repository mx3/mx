
# ===============================================================================#
# = for special characters: 1. save from excel as .csv, 2. open in textwrangler= # 
# = 3.change to utf8, windows line endings   
# =                                
# ===============================================================================#

=begin
  TODO need to add type information to taxon upload; make available in help
=end   
require 'tempfile'
require 'csv'

$USAGE = 'Call like: "rake mx:load_tree_genus_names file=/Users/Irene/Desktop/treehopper_genera_upload.csv start=0 end=100 person=1 project=1 rank=Genus RAILS_ENV=development"' 


namespace :mx do
  desc $USAGE
  task :load_tree_genus_names => [:environment, :project, :person] do

    # 0 - Heirarchy; this feild is not used, internal notes field not used in upload
    # 1 - Rank # added in notes and todo add as tag
    # 2 - Name #cannot be blank
    # 3 - Author
    # 4 - Date
    # 5 - Suffex date letter, ref table in mx; presently not used
    # 6 - Page : page_first_appearance
    # 7 - Original reference, will add later; presently not used
    # 8 - Parent #cannot be blank
    # 9 - Status #to do add as tag
    # 10 - Note on Status
    
   @file = ENV['file']
   @start = ENV['start'].to_i
   @end = ENV['end'].to_i
   @rank = ENV['rank'].to_s
   @person = ENV['person'].to_s
   @project = ENV['project'].to_s
   
   
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

    parent = n[8]
    
    # ===========================================================================#
    # = go through all the ranks in order; manually change status;             = #
    # = do valid than invalid names                                            = # 
    # = have to start with the valid names first then go through invalid names = #
    # ===========================================================================#

  if n[1] == @rank && n[9] != 'valid'
  #if n[1] == @rank && n[9] == 'valid'
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
       parent = n[8] # parent is either the parent of valid name
       valid_name = n[2] # valid_name is updated later for invalid names that include parent as valid names
       rank = n[1]
       status = n[9]
       page_validated_on = n[6]
       import_notes = "loaded from rake task, "+ ENV['file'].to_s

       if n[10] != nil
         notes = "status_notes:" + n[10]
       end
  
  if n[9] == 'valid'
    valid_name = n[2]
         @names_to_add.push(TaxNames.new(:parent => parent, :name => name, :author => author, :year => year, :rank => rank, :status => status, :valid_name => valid_name, :notes => notes, :page_validated_on => page_validated_on, :import_notes => import_notes, :group => group))

  else # for names that are not valid
      valid_name = n[8]
         @names_to_add.push(TaxNames.new(:parent => parent, :name => name, :author => author, :year => year, :rank => rank, :status => status, :valid_name => valid_name, :notes => notes, :page_validated_on => page_validated_on, :import_notes => import_notes, :group => group))
     
     end #end valid false
   end #end valid true
 end
        puts "ALL NAMES:  (#{@names_to_add.size} total)"
        @names_to_add.each do |n|
          puts [n.name, n.author, n.year, n.notes, n.valid_name, n.notes, n.page_validated_on, n.import_notes, n.status, n.rank].compact.join(" ") + " [#{n.parent}] " 

  end

   raise if !person = Person.find($person_id)
   puts "start: " + Time.now.to_s
   @range = (@start..@end) # going to do these in small batches
   log = File.new("log_#{@start}-#{@end}.txt", "w+")
 
    
   #added keywords rank and status if do not exist
   Keyword.transaction do
   
        if kwd_status = Keyword.find(:first, :conditions => {:keyword => "status"})
          log.puts "keyword already exists => #{kwd_status.keyword} [#{kwd_status.id}]"
        else
            kwd_status = Keyword.new(:keyword => "status", :shortform => "status", :html_color => "76D5E4")
            kwd_status.save
            kwd_status = Keyword.find(:first, :conditions => {:keyword => "rank"})
            log.puts "added keyword => #{kwd_status.keyword} [#{kwd_status.id}]"
          end
     
        if kwd_rank = Keyword.find(:first, :conditions => {:keyword => "rank"})
          log.puts "keyword already exists => #{kwd_rank.keyword} [#{kwd_rank.id}]"
        else  
            kwd_rank = Keyword.new(:keyword => "rank", :shortform => "rank", :html_color => "DFB362")
            kwd_rank.save
            kwd_rank = Keyword.find(:first, :conditions => {:keyword => "rank"})
            log.puts "added keyword => #{kwd_rank.keyword} [#{kwd_rank.id}]"
          end
   end # end transaction
   

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
                              :iczn_group => n.group, :parent_id => parent.id, :notes => n.notes},
              :person => person
            )
            log.puts "added: " + [n.name, n.author, n.year].compact.join(" ") + " [#{n.parent}] " + (n.valid_name ? " =#{n.valid_name}" : "") +  " [mxid: #{new_name.id}]"
          end
        end
          
          
          # update rank and status tags
          log.puts "\nadding rank and status tags"
          @names_to_add[@range].each do |n|
            if !n.rank.blank?
              new_name = TaxonName.find(:first, :conditions => {:name => n.name})
              kwd_rank = Keyword.find(:first, :conditions => {:keyword => "rank"})
              t = Tag.new(:addressable_type => 'TaxonName', :addressable_id => "#{new_name.id}", :keyword_id => "#{kwd_rank.id}" , :notes => "#{n.rank}")
              t.save 
           end

            if !n.status.blank?
              new_name = TaxonName.find(:first, :conditions => {:name => n.name})
              #new_name = TaxonName.find(:first, :conditions => {:name => n.name, :author => n.author, :year => n.year})
              kwd_status = Keyword.find(:first, :conditions => {:keyword => "status"})
              t = Tag.new(:addressable_type => 'TaxonName', :addressable_id => "#{new_name.id}", :keyword_id => "#{kwd_status.id}" , :notes => "#{n.status}")
              t.save 
          end
        end
        
       

        # now do a pass to update names to valid names for names that entered as not valid.  This field is NULL in valid names!
        log.puts "\nupdating pointers to valid names:"
        @names_to_add[@range].each do |n|
          if n.valid_name != n.name
            if !valid_name = TaxonName.find(:first, :conditions => {:name => n.valid_name})
              log.puts "failed (no valid name found): " + [n.name, n.author, n.year].compact.join(" ") + " [#{n.parent}] " 
              next
            else
              tn = TaxonName.find(:first, :conditions => {:name => n.name})
              tn.valid_name_id ? tn.valid_name_id = valid_name.id : ""
              tn.save
              log.puts "valid name update: " + [n.name, n.author, n.year].compact.join(" ") + " [#{n.parent}] " + (n.valid_name ? " =#{n.valid_name}" : "") + " [mx #{tn.id} => #{valid_name.id}]"
            end
          end
        end
        
        
      #update parents  
      log.puts "\nupdating pointers to parents:"
      @names_to_add[@range].each do |n|
       if "#{n.valid_name}" == "#{n.parent}"
            if !pn = TaxonName.find(:first, :conditions => {:name => n.valid_name})
            next
           else
              tn = TaxonName.find(:first, :conditions => {:name => n.name}) #only picks the first name; may very well be a issue if more than one of the same name in an uplaod
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


    class TaxNames
      attr_accessor :parent, :name, :author, :year, :rank, :status, :valid_name, :notes, :group, :page_first_appearance, :import_notes, :page_validated_on
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
        @rank = opts[:rank]
        @status = opts[:status]
      end #end initialize
    end #end class
  end #end namespace



