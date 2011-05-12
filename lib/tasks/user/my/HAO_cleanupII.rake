# not included in environment
# require 'ruby-debug'

# THE ORDER OF THIS UPDATE 
# 1 - reload the data uptil but not including migration 20100301210739_create_labels
# 2 - add migrations from create_labels to update_sensu_with_votes_confdience_position_etc
# 3 - migrate the data
# 4 - run this task ('rake mx:HAO_cleanupII project=32 person=2')
# 5 - add any migrations post update_sensu_with_votes_confdience_position_etc
# 6 - migrate again

# 7 - manually delete deprecated keywords (and therefor tags)

$USAGE = 'one time use only, some example "migration" code' 

namespace :mx do
  desc $USAGE

  def tag_status(t)
    #  puts "tag.id:#{t.id} ro:#{t.referenced_object}" 
  end

  def handle_tags
    # migrate Tags
    to_label = [181,250,219,251,268,269,270]
    to_class = [235,179,226,228,238,244,257]
    on_labels_ro_to_class = [229,230,252,206]
    label_AND_class_if_definition_exists = [128,258,231]
    on_class_ro_to_label = [129]
    class_if_definition_exists = [187]
    @proj = Proj.find($proj_id, :include => [:tags])
   
    Tag.transaction do
      puts "to_label"
      to_label.each do |k|
        @proj.tags.by_keyword(Keyword.find(k)).each do |t|
          tag_status(t) 
        
          t.addressable_type = 'Label'
          t.save!
        end
      end
       
      puts "to_class"
      to_class.each do |k|
        kwd = Keyword.find(k)
        puts "keyword: #{kwd.keyword}"
        @proj.tags.by_keyword(kwd).each do |t|
#          tag_status(t) 
          if to = t.tagged_obj
            if to.description.blank? || to.description == ""
              puts "probable error on tag:#{t.id}, tagged Part #{to.id}:#{to.name} with definition empty -- Tag is being deleted"
              t.destroy
            else
              t.addressable_type = 'OntologyClass'
              t.save!
            end
          end
        end
      end
      
      puts "on_labels_ro_to_class"
      on_labels_ro_to_class.each do |k|
        @proj.tags.by_keyword(Keyword.find(k)).each do |t|
#         tag_status(t) 
      
          t.addressable_type = 'Label'
          t.referenced_object = t.referenced_object.gsub("part", "ontology_class") if t.referenced_object =~ /part/i
          t.save!
        end
      end

      puts "label_AND_class_if_definition_exists"
      label_AND_class_if_definition_exists.each do |k|
        kwd = Keyword.find(k)
        @proj.tags.by_keyword(kwd).each do |t|
          if t.addressable_type == "Part" 
#            tag_status(t) 
            
            to = t.tagged_obj
            # convert present to label 
            t.addressable_type = 'Label'
            t.save

            # add a tag to OntologyClass
            if !(to.description.blank? || to.description == "") 
              if obj = OntologyClass.find(t.addressable_id)
               nt = Tag.create_new(:obj => obj, :keyword => kwd, :notes => t.notes, :referenced_object => t.referenced_object, :ref_id => t.ref_id, :pages => t.pages, :pg_start => t.pg_start, :pg_end => t.pg_end, :proj_id => t.proj_id)  
               puts "referenced object where there shouldn't be one? #{nt.referenced_object}" if !nt.referenced_object.blank?
               nt.save!
              end
            end 
          end
        end
      end

      puts "on_class_ro_to_label"
      on_class_ro_to_label.each do |k|
        @proj.tags.by_keyword(Keyword.find(k)).each do |t|
        # tag_status(t) 
    
          t.addressable_type = 'OntologyClass'
          t.save!
          t.referenced_object = t.referenced_object.gsub("part", "label") if t.referenced_object =~ /part/i
        end
      end

      puts "class_if_definition_exists"
      i = 0
      class_if_definition_exists.each do |k|
        @proj.tags.by_keyword(Keyword.find(k)).each do |t|
          # tag_status(t) 
          to = t.tagged_obj
          if !(to.description.blank? || to.description == "")
           t.addressable_type = 'OntologyClass'
           t.save!
           i += 1
          end
        end
      end
      puts "updated #{i} class_if_defition_exists #{class_if_definition_exists.join(", ")}"

    end # end trans
  end

  def create_new_labels_for_plural_forms
    i = 0
    Tag.by_keyword(130).each do |t|
      if l =  Label.find(t.tagged_obj.id) 
        # puts "[#{l.name}]", t.id 
        ln = Label.new(:plural_of_label => l, :name => t.notes.strip) # so we don't have to mess with more whitespace blunders
        ln.save!
        i += 1
      else
        puts "can't find the singular of #{t.notes}"
      end
    end
    puts "created #{i} new plural labels"
    # kwd ID 130
  end

  def create_needed_sensus
    puts "processing sensus..."
   # create sensu links using HAO reference for those sensus that don't exist 
    Sensu.transaction do 
      i = 0
      @proj.parts.each do |p|
        if !p.ref_id.blank? && !p.description.blank? && (p.description != "") 
          if s = Sensu.find(:first, :conditions => {:label_id => p.id, :ontology_class_id => p.id, :ref_id => p.ref_id})
            puts "found sensu for #{p.id}, doing nothing" # do nothing
          else
            Sensu.create!(:ref => p.ref, :label_id => p.id, :ontology_class_id => p.id, :notes => 'autocreated on class/model migration')
            i += 1
          end
        end
      end
      puts "wrote #{i} new Sensus"
    end

  end

  # runs the tasks above
  task :HAO_cleanupII => [:environment, :project, :person] do
      print "starting..."
      @proj = Proj.find($proj_id)
      begin 
        OntologyClass.transaction do 
          create_new_labels_for_plural_forms
          handle_tags
          create_needed_sensus 
          puts "passed transactions ..."
         # raise 
        end 
        puts "done!" 
    
      rescue       
        print "uhoh!\n" 
        raise
      end
    print "\ndone!\n"
  end # end task

end # end namespace

