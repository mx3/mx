# not included in environment
require 'yaml'

# metafile is a YAML formatted file, with each entry like this, see mx_meta_eg.yaml in /lib/task/examples/

namespace :mx do
  namespace :matrix do
    
    class LoadFile < File
      def content_type
        'text/plain'
      end
      
      def original_filename 
        self.class.basename(path)
      end
      
      def size 
        self.class.size(path)
      end
    end

    def load_meta(f)
      meta = []
      file_path =   ENV['datapath'] + "/" + f
      raise "Unable to read from file '#{file_path}'!\n" if not File.readable?(file_path)  
      meta = YAML.load_file(file_path)
      meta
    end

    def new_matrix(options)
       @opt = {
            :title => "None provided for Rake load at #{Time.now}",  # the matrix name
            :generate_short_chr_name => false,
            :generate_otu_name_with_ds_id => false, # data source, not dataset
            :generate_chr_name_with_ds_id => false,
            :match_otu_to_db_using_name => false,
            :match_otu_to_db_using_matrix_name => false,
            :match_chr_to_db_using_name => false,
            :generate_chr_with_ds_ref_id => false, # data source, not dataset
            :generate_otu_with_ds_ref_id => false
          }.merge!(options)
          
      begin
        $person_id = @opt[:person_id] # for the magic before save
        $proj_id = @opt[:proj_id] 

        # create the underlying dataset and datasource
        @file =  LoadFile.new(@opt[:file])
      
        @ds = Dataset.new()
        @ds.uploaded_data = @file 
        @ds.save!

        # make a reference, though we don't really need this step, could configure to blind load without dataset/datasource
        @data_source = DataSource.new(:name => @opt[:data_source_name])
        @data_source.dataset_id = @ds.id
        @data_source.save!

        # its all in here!
        @ds.convert_nexus_to_db(@opt)

        # puts h.to_yaml 

        rescue ActiveRecord::RecordInvalid => e
          raise e
        raise
      end
      true
    end


     desc "Truncate all matrix data for a given project, can't be used in production."
      task :truncate => [:environment] do # this line runs the other rake tasks in the array [], in this case loading the environment, you could chaing tasks together this way.
        $USAGE = 'Call like: "rake mx:matrix:truncate proj=1".  You can not run this in production.'
        # grab the command line options

        raise "You can't use this in production!" if RAILS_ENV == "production"
        raise "No project id provided " if !ENV['proj']
        @proj_id = ENV['proj']        
        raise "No project #{@proj_id}" if ! @proj = Proj.find(@proj_id)
      

        # here is a little bit of a trick, we must find a person who belongs to the project and set a variable
        # that is checked before an object w/in mx is delete, lets just find the first person in the project
        # person_id is the variable that needs to be set.  we need to do something similar with the $proj_id variable
        $person_id = @proj.people.first.id
        $proj_id = @proj.id

        # tags get automatically destroyed when their resepective tagged object is nuked
        puts "\nNuking..."

        begin # this is a simple error catching bit, if anything goes wrong b/w it and rescue the code in rescue is called
          Proj.transaction do |p| # this is a MySQL transaction, everything must work without error within it, or nothing happens at all
            @proj.otus.each do |o|
              o.destroy # this chain destroys tags and codings and tags on those codings (:dependent => destroy relationships in the model)
              # note that destroying an Otu destroy just about everything else in the DB associatied with it!
            end 
            @proj.chrs.each do |c|
              c.destroy # chain destroys states and tags on chrs
            end
            @proj.mxes.each do |m|
              m.destroy
            end
          end
        rescue ActiveRecord => e
          puts "FAILED! No data nuked, error: #{e}" and break
        end

        puts "Nuked!\n"
        # that's all!
      end

     
    desc "Load one or more matrices."
      task :load => [:environment] do

        $USAGE = 'Call like: "rake mx:matrix:load datapath=/data/my_matrices metafile=foo.txt project=23 person=4 RAILS_ENV=[production|development]".' +  
          "\nYou need metafile=some_file. See http://hymenoptera.tamu.edu/wiki/index.php/Rake_tasks for explanation of the metafile format."
        # grab the command line options
        @meta = ENV['metafile']
        @proj_id = ENV['project']
        @person_id = ENV['person']
        
        raise "No path to data given (datapath=/data/mymatrices)" if !ENV['datapath']

        # pass one only of @meta (1 to many matrices) or @file (a matrix with no other options)
        if !@meta
          puts "ERROR " + $USAGE
          abort # might be better way to do this
        end

        if !@proj_id
          puts "\nProject to load to not specified (project=id)!\n"  + $USAGE
          abort
        end

        if !@person_id
          puts "\nPerson not specified (person=id)!\n " + $USAGE
          abort
        end

        # read the metadata
        meta = load_meta(@meta) # load_meta throws its own error if it fails

        # before we start we can check to see if the required data is present
        @proj = Proj.find(@proj_id)
        raise "Project #{@proj_id} doesn't exist." if !Proj.find(@proj_id)
        
        @person = Person.find(@person_id)
        raise "Person #{@person_id} doesn't exist." if !Person.find(@person_id)

        # check that the person in question belongs to the project
        raise "Supplied person #{@person.display_name} isn't a member of #{@proj.display_name}!" if !@proj.people.include?(@person)

        # check that the supplied references exist
        meta.keys.each do |f|
          if f[:data_source_ref_id] # you don't have to supply a reference
            raise "Reference with id #{meta[f][:data_source_ref_id]} not found for file #{f}." if !Ref.find(meta[f][:data_source_ref_id])
          end
        end

        # check that the files exist
        meta.keys.each do |f|
            raise "Unable to read the matrix '#{f}'" if not File.readable?(ENV['datapath'] + "/" + f)  
        end

        puts "\nMetadata seem to be ok, begining to parse ...\n"

        i = 0
        begin
          ActiveRecord::Base.transaction do
            meta.keys.sort.each do |f|  # each key is a matrix filename
              puts "Starting 1/#{meta.keys.size} #{f} ... "
              if not new_matrix(meta[f].update(:file => "#{ENV['datapath']}/#{f}", :proj_id => @proj.id, :person_id => @person.id)) 
                puts "Failed on matrix #{f}."
                raise
              end
            
              i += 1
                puts "parsed!\n"
              end
            end

        rescue ActiveRecord::RecordInvalid => e
          puts "ERROR, rescued in main loop. \n #{e}"
        end

        if i == meta.keys.size
          puts "\nsuccess, loaded #{i} matrices\n" 
        else
          puts "Failed at some point, nothing was loaded."
        end
      end
        
  
    desc "Debug a nexus file against the parser."
    task :debug => [:environment] do  

      $USAGE = 'Call like: "rake mx:matrix:debug file=some_matrix_file.nex.' 
      @file = ENV['file']
      raise $USAGE if !@file
    
      require File.expand_path(File.join(File.dirname(__FILE__), '../../vendor/plugins/nexus_parser/lib/nexus_file.rb'))
      
      raise "Unable to read the matrix '#{@file}'" if not File.readable?( @file )  

      begin
        file = File.read(@file) # MX_test_01.nex
        nf = parse_nexus_file(file)   
      rescue NoMethodError => e
        puts "No method error"
        raise e
      rescue ParseError => e
        puts "Error in parsing.\n"
        raise e
      end

      if nf.characters.size > 0 && nf.taxa.size > 0 && nf.codings.size > 0 
        puts "\nFile appears to have parsed without errors, characters, taxa, and codings present.\n"
        puts "Parsed taxa: #{nf.taxa.size}\n"
        puts "Parsed characters: #{nf.characters.size}\n"
        puts "Parsed matrix rows: #{nf.codings.size}\n"

        puts "\nNotes/tags for taxa: \n"
        i = 0
        nf.taxa.each do |t|
          if t.notes.size != 0
            i += 1
          puts "#{t.name}: " +  t.notes.join(", ")
          end
        end
        puts "none!" if i == 0

        puts "\n"

        puts "Notes/tags for characters: \n"
        nf.characters.each do |c|
          puts "#{c.name}: " + (c.notes.size == 0 ? "none" : c.notes.collect{|i| i.note}.join(", "))
        end

        puts "\n\nNotes/tags for Codings (row,col): \n"

         t = 0
         nf.codings.each_with_index do |x,i|
          x.each_with_index do |y,j|
            if y.notes.size > 0 
              puts "#{i + 1}, #{j + 1}\n" 
              t += 1
            end
          end
        end

        if t == 0
          puts "NONE!" 
        else
          puts "\n#{t} Tags/Notes for Codings read \n\n"
        end

        # check for ? cells with notes
        nf.codings.each_with_index do |x,i|
          x.each_with_index do |y,j|
            puts "WARNING: Coding of cell #{i + 1}, #{j + 1} (row,col) is '?' and has a note, this note will NOT be translated to a tag if added to the database.\n" if y.notes.size > 0  && y.states.size == 1 && y.states[0] == "?" 
          end
        end
        
      else
        puts "Possible errors parsing, one of characters, taxa or codings not read.\n"
      end

    end

  end
end




### should likely make these tasks




