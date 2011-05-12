# not included in environment
# require 'breakpoint'
require 'tempfile'

$USAGE = 'Call like: "rake mx:load_images img_path=d:\temp\images\ project=13 person=2 metafile=foo.txt"'

# allows regular files to act like the funny CGI tempfile class that the Image model is used to dealing with
class LoadFile < File
  def local_path 
    self.class.expand_path(path)
  end
  
  def original_filename 
    self.class.basename(path)
  end
  
  def size 
    self.class.size(path)
  end
end

def load_image_meta(f)
  # file describing the images to load should be this format (tab delimited)
  # 0 [otu_id || new OTU name (new OTUs for *every* name) ]
  # 1 full_image_file_name
  # 2 part 
  # 3 view
  # 4 stage
  # 5 sex
  # 6 type
  # 7 notes (image description)
  # 8 taken by
  # 9 mx_specimen_id
  
  meta = []
  raise "Unable to read from file '#{f}'" if not File.readable?(f)   
  IO.readlines(f).collect{|l| l.chomp!; meta.push( l.split("\t"))}
  meta
end

def new_image(meta)
    
  begin
      @m = meta
    
      if not (@m[0].to_i > 0)
        # make a new OTU
        o = Otu.create!(
        :name => @m[0],
        :proj_id => $proj_id,
        :creator_id => $person_id,
        :updator_id => $person_id
        ) or raise "couldn't create an OTU"
      else
        o = Otu.find(@m[0].to_i)
      if o == nil
      puts "failed to find OTU" if not o
      raise
      end
      end

      if not File.exists?("#{ENV['img_path']}#{@m[1]}")
        puts "Unable to find the image '#{ENV['img_path']}#{@m[1]}'"
        raise
      end    
    
      # LoadFile is a class that subclasses File to add two methods (to emulate the special CGI tempfile class)
      i = Image.new(:file => LoadFile.new("#{ENV['img_path']}#{@m[1]}"), :technique => meta[6])
      i.save!
      
      # deal with parts
      if meta[2].to_s.size > 0
      unless p = Part.find(:first, :conditions => ["name = ? and proj_id = ?", meta[2], $proj_id] ) 
        unless p = Part.new(:name => meta[2], :creator_id => $person_id, :updator_id => $person_id, :proj_id => $proj_id)
          puts 'problem with part'
        end
        p.save or raise "couldn't save part"
      end
      end
  
      # deal with image_views
      if meta[3].to_s.size > 0
        unless iv = ImageView.find(:first, :conditions => ["name = ?", meta[3]] )
          unless iv = ImageView.new(:name => meta[3], :creator_id => $person_id, :updator_id => $person_id)
          puts 'problem with view'
          end
          iv.save or raise "couldn't save image view"
        end
      end
  
      # :taken_by => meta[7],
      # :specimen_id => meta[8],

      idscr = ImageDescription.create!(
       :otu_id => o.id,
       :proj_id => $proj_id,
       :image => i,
       :image_view => iv,
       :part => p,
       :stage => meta[4],
       :sex => meta[5],   
       :notes => meta[7])   or raise 'failed to make image description'
     
    # we only catch RecordInvalid errors, all others get passed up the stack
    rescue ActiveRecord::RecordInvalid
      # if the only error is that the image has already been stored in the db, we print a message and continue
      if i && i.errors.count == 1 && i.errors.on("file") && i.errors.on("file")["has already been stored in the database"]
        i.errors.each_full {|msg| puts msg}
      # in all other cases we raise the error higher, which will halt execution
      else
        raise
      end
    end
end

namespace :mx do
  desc $USAGE
  task :load_images => [:environment, :project, :person] do
  
    @file = ENV['metafile']

    if not $proj_id or not $person_id or not @file 
      puts "ERROR " + $USAGE
      abort # might be better way to do this
    end

    @proj = Proj.find($proj_id)

    $path = ENV['img_path'] # check for trailing /

    ActiveRecord::Base.transaction do
      meta = load_image_meta(@file)
      i = 0
      for l in meta do
        if not new_image(l)
          puts "row #{i.to_s} failed"
        end
        puts(i += 1)
      end
    end
  end
end



