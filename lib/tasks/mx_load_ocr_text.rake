require 'tempfile'

# This task loads text files to Ref#ocr_text and if an ontology_proj_id is provided then runs Ref#count_parts against
# the imported text and the ontology in the referenced project.
#
# Files need to be named in the format mx_<id> where <id> is an existing Ref#id. E.g. 'mx_123.txt'.  
#
# !! If files exist that are not in this format OR references are not found the whole transaction fails. 

# !! WARNING: If Ref#ocr_text exists then it it overwritten by the text in the file.

# !! WARNING: you may have to alter your you mysql .ini file to increase the max_allowed_packet from 1M to something like 8M or 32M 
# when running this task.

$USAGE = 'Call like: "rake mx:load_ocr_text path=~/Downloads/my_files person=2 ontology_proj_id=2". You should also review the comments in the task file.'

namespace :mx do
  desc $USAGE
  task :load_ocr_text => [:environment, :person] do
 
    raise 'You must include a path like "path=c:\foo."' if !ENV['path']
    files = Dir["#{ENV['path']}/*"] 

    begin
      proj = Proj.find(ENV['ontology_proj_id']) if ENV['ontology_proj_id'] 
      Ref.transaction do
        files.each do |f|
          puts "reading: #{f}\n"
          if ref = Ref.find(f.split("_").last)
            puts "matches: #{ref.display_name}"
            ref.ocr_text = File.read(f)
            ref.save!
            if proj
              print "counting..."
              ref.count_parts(proj.id)
              puts "done\n\n"
            end
           
          else
            raise
          end
        end
      end
    rescue Exception => e
      puts "Failed to read and/or write all files: #{e}."
    end

  end
end

