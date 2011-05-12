# not included in environment
# require 'ruby-debug'

$USAGE = 'one time use only, some example "migration" code' 

def syn_ontologies
 Ontology.find(:all, :conditions => {:isa_id => 41, :proj_id => 32})
end

namespace :mx do
  desc $USAGE

  def make_obsolete_syns_syn
    Ontology.find(:all, :conditions => {:isa_id => 43, :proj_id => 32}).each do |o|
      o.isa_id = 41
      o.save
    end
  end

  def move_syns_to_tags 
      syn_ontologies.each do |o|
        t = Tag.new(:addressable_type => 'Part', :addressable_id => o.part1.id, :notes => "mxid_#{o.part2.id}", :keyword_id => 225)
        t.save 
      end
  end

  def number_HAO 
    Part.fill_blank_xrefs(:parts => (Proj.find($proj_id).parts.not_acronym - Proj.find($proj_id).restrictor_excluded_parts), :proj_id => 32, :prefix => 'HAO', :padding => 7) 
  end

  def make_sensu_for_syns_with_non_curator_refs 
    syn_ontologies.each do |o|
      if !o.part1.ref_id.blank? && !o.part1.description.blank? && o.part1.ref_id != 67862  && o.part1.ref_id != 67791 && o.part1.ref_id != 67841 
        # make a sensu tag
        t = Tag.new(:addressable_type => 'Part', :addressable_id => o.part1.id, :keyword_id => 234, :ref_id => o.part1.ref_id)
        t.save 
        t.creator_id = o.creator_id
        t.save

        # make a alternative definition tag
        t2 = Tag.new(:addressable_type => 'Part', :addressable_id => o.part2.id, :keyword_id => 129, :notes => "#{o.part1.description} ! #{o.part1.obo_dbxref}", :ref_id => o.part1.ref_id)
        t2.save 
        t2.creator_id = o.creator_id
        t2.save

        # clear the description and reference from the part
        o.part1.ref_id = nil
        o.part1.description = nil
        o.part1.ref_id = nil
        o.part1.save
      end 
    end
  end

  def nuke_synonym_rels 
      syn_ontologies.each do |o|
        o.destroy
      end
  end

  def make_concept_and_used_by_tags_sensu
    Tag.find(:all, :conditions => 'proj_id = 32 AND (keyword_id = 213 OR keyword_id = 216)').each do |t|
        t.keyword_id = 234
      t.save
    end
  end

  def update_syn_tags_with_HAO 
    # this needs to first be mx ids
    Tag.find(:all, :conditions => {:proj_id => 32, :keyword_id => 225}).each do |t|
      t.notes = Part.find(t.notes.split("_")[1].to_i).obo_dbxref
      t.save
    end
  end

  def cleanup_missing_created_on
    Part.find(:all, :conditions => {:proj_id => 32}).each do |p|
      p.created_on = Time.now if( p.created_on == nil || p.created_on == "")
      p.save
    end
  end

  # runs the tasks above
  task :HAO_cleanup => [:environment, :project, :person] do
      print "starting..."
      begin 
        Ontology.transaction do 
          make_obsolete_syns_syn     
          move_syns_to_tags
          number_HAO
          make_sensu_for_syns_with_non_curator_refs
          nuke_synonym_rels
          make_concept_and_used_by_tags_sensu
          update_syn_tags_with_HAO
          cleanup_missing_created_on
        end 
      rescue       
        print "uhoh!\n" 
        raise
      end
    print "\ndone!\n"
  end # end task

  task :HAO_remove_acronyms => [:environment, :project, :person] do
    print "starting..."
      begin
        @acronyms = Part.find(:all, :conditions => {:is_acronym => true, :proj_id => 32}) 
        @count = 0 
        Ontology.transaction do
          @acronyms.each do |a|
            if tags = a.tags.by_keyword(225) # the synonym kw
              tags.each do |t|
                if ro = t.referenced_object_object
                  Tag.create!(:addressable_id => ro.id, :addressable_type => "Part", :keyword_id => 251, :notes => a.name)
                  @count += 1
                end
              end 
            end
          end
          # delete the acronyms
          @acronyms.each do |a|
            a.destroy
          end
        end 
      rescue       
        print "uhoh!\n" 
        raise
      end
    puts "created #{@count} tags ... all done!\n"
  end

end # end namespace



