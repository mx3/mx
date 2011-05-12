namespace :mx do

  require 'tempfile'
  require 'csv'
  
  # ** IMPORTANT If you use faster_csv you must now include the :environment like 'task :mytask => [:environment]' 
  # require 'faster_csv' <- this does not work with RubyGems 1.3.6

  def get_csv(myfile, tabbed = false)
    recs = []
    raise "Unable to read from file '#{myfile}'" if !File.readable?(myfile)   

    if tabbed
       recs = CSV::parse(File.open(myfile, 'r'){|f| f.read}, :col_sep => "\t") # this doesn't work on Tab seperated quote delimited
    else
       recs = CSV::parse(File.open(myfile, 'r'){|f| f.read})
    end   
    
    recs
  end
  
  def get_fastercsv(myfile, tabbed = false)
    recs = []
    raise "Unable to read from file '#{myfile}'" if !File.readable?(myfile)   
    if tabbed
       recs = FasterCSV.read(myfile,  :col_sep => "\t")
    else
       recs = FasterCSV.read(myfile )
    end   
    
    recs
  end

  task :person do
    raise "You must specify 'person=person_id'" unless ENV["person"]
    $person_id = ENV["person"].to_i
  end

  task :project do
    raise "You must specify 'project=project_id'" unless ENV["project"]
    $proj_id = ENV["project"].to_i
  end

  desc "Removes all characters other than A-Za-z from author initials."
  task :clean_author_initials => [:environment, :person] do
    puts "updating authors..."
    pattern = /[^A-Za-z]/
    Author.transaction do
      Author.find(:all).each do |a| 
        if a.initials =~ pattern
          a.initials.gsub!(pattern, '')
          a.save!
        end
      end
    end
  end

  desc "Update all Ref display names"
  task :update_ref_display_names => [:environment, :person] do
    puts "updating display names..."
    Ref.transaction do
      Ref.find(:all).each {|r| r.save! }
    end
  end

  desc "Export a copy of the mx source code and prepare for release, *nix only"
  task :prepare_release do
    require 'find'

    puts "checking out source..."
    temp_dir = "/tmp/mx_temp"
    `rm -rf #{temp_dir}` # just in case there is crap there already
    svn = `svn co file:///Volumes/data/svn/mx #{temp_dir}`
    rev = svn.split.last[/\d+/]
    excludes = ["trunk/app/controllers/public/site","trunk/app/views/public/site","trunk/public/site"]
    puts "filtering..."
    Find.find(temp_dir) do |path|
      # remove unwanted public directories and all .svn stuff
      if FileTest.directory?(path) and (excludes.any? {|dir| path.index(dir) } or File.basename(path) == ".svn")
        `rm -rf #{path}`
        Find.prune 
      end

      # remove emails from configuration
      if path.index("trunk/config/environment.rb")
        text = File.read(path).sub(/^NOTIFICATION_RECIPIENTS\s.*/, "NOTIFICATION_RECIPIENTS = 'foo@bar.com'")
        text.sub!(/^HOME_SERVER\s.*/, "HOME_SERVER = 'foo.bar.com'")
        text.sub!(/^MAIL_SERVER\s.*/, "MAIL_SERVER = 'foo.bar.com'")
        text.sub!(/^HELP_WIKI\s.*/, "HELP_WIKI = 'foo.bar.com/wiki'")
  
        text.sub!(/^GMAPS_KEY_PRODUCTION\s.*/, "GMAPS_KEY_PRODUCTION = 'get a key at the Google maps api site'")
        text.sub!(/^GMAPS_KEY_DEVELOPMENT\s.*/, "GMAPS_KEY_DEVELOPMENT = 'get ANOTHER key at the Google maps api site'")
     
        # truncates existing file
        File.open(path, "w") {|f| f.print(text) }
      end

      if path == "#{temp_dir}/trunk/views/layouts"  
        puts Dir["#{path}/*"]
      end
    end

    # compress
    `mv #{temp_dir}/trunk #{temp_dir}/mx`
    `tar -C #{temp_dir} -czf ~/mx_#{rev}.tar.gz mx`

    # clean up
    `rm -rf #{temp_dir}`
  end

end
