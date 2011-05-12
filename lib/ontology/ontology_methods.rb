# you must restart the server when changes are made to this file

module Ontology

module OntologyMethods

  # Ontology::OntologyMethods::
  class BatchParseError < ApplicationController::BatchParseError
  end

  OBO_TYPEDEFS = ['is_a', 'disjoint_from', 'instance_of', 'inverse_of', 'union_of', 'intersection_of']

  def self.auto_complete_search_result(params = {})
    tag_id_str = params[:tag_id]
    return false if (tag_id_str == nil  || params[:proj_id].blank?)

    value = params[tag_id_str.to_sym].split.join('%') # hmm... perhaps should make this order-independent

    lim = case params[tag_id_str.to_sym].length
    when 1..2 then 3
    when 3..4 then 5
    else lim = false # no limits
    end

    result = []
    result += Label.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id = ?", "%#{value}%", value.gsub(/\%/, ""), params[:proj_id]], :order => "length(name), name", :limit => lim )
    result += OntologyClass.find(:all, :conditions => ["(definition LIKE ? OR id = ? OR xref = ?) AND proj_id = ?", "%#{value}%",  value.gsub(/\%/, ""), value, params[:proj_id]], :limit => lim )
    result += Tag.find(:all, :conditions => ["(tags.notes LIKE ? OR tags.id = ? OR keywords.keyword = ?) AND tags.proj_id = ? ", "%#{value}%",  value.gsub(/\%/, ""), "%#{value}%", params[:proj_id]], :limit => 15, :include => [:keywords, :ref], :order => 'tags.updated_on DESC' )
    result 
  end

  def self.search_redirect(params = {})
    return {:controller => :ontology, :action => :index} if params[:hidden_field_class_name].blank?
    {:controller => params[:hidden_field_class_name].tableize.singularize.to_sym, :id => params[:onto_search][:search_id], :action => :show}
  end

  def self.homonyms(options = {})
    opts = {
      :proj_id => nil, 
    }.merge!(options.symbolize_keys)
    return nil if opts[:proj_id].nil?
    result = []
    Proj.find(opts[:proj_id]).labels.ordered_by_name.each do |l|
      result.push l if l.ontology_classes.size > 1
    end
    result
  end

  def self.search_result(options = {})
    opts = {
      :include_labels => true,
      :include_ontology_classes => true,
      :search_string => '',
      :exact_match => false,
      :proj_id => nil, 
      :limit => false, # or an integer, false is no limit
    }.merge!(options.symbolize_keys)

    result = {}
    result[:ontology_classes] = []
    result[:labels] = []
    return result if (opts[:search_string] == nil  || opts[:proj_id].nil?)

    if opts[:exact_match]
      value =  opts[:search_string]
    else
      value = opts[:search_string].split.join('%') # hmm... perhaps should make this order-independent
    end

    if opts[:include_labels]
      result[:labels] += Label.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id = ?", "%#{value}%", value.gsub(/\%/, ""), opts[:proj_id]], :order => "length(name)", :limit => opts[:limit] )
    end
    if opts[:include_ontology_classes]
      result[:ontology_classes] += OntologyClass.find(:all, :conditions => ["(definition LIKE ? OR id = ?) AND proj_id = ?", "%#{value}%",  value.gsub(/\%/, ""), opts[:proj_id]], :limit => opts[:limit] )
    end
    result
  end

  def self.persist_sensus_from_file(options = {}) # :yields: [Sensu, ... Sensu]
    opt = {
      :sensus_from_file_result => nil,
      :proj_id => nil, 
      :person_id => nil,
      :written_by_ref_id => nil
    }.merge!(options)

    raise Ontology::OntologyMethods::BatchParseError, "Provide a person_id" if opt[:person_id].nil?
    raise Ontology::OntologyMethods::BatchParseError, "Provide a proj_id" if opt[:proj_id].nil?
    raise Ontology::OntologyMethods::BatchParseError, "Person with provided person_id not found." if !Person.find(opt[:person_id])

    old_person_id = $person_id
   
    $person_id = opt[:person_id]
    $proj_id = opt[:proj_id] 

    proj = Proj.find($proj_id)
    created_sensus = []
    begin
      ActiveRecord::Base.transaction do
        [:references, :labels, :ontology_classes].each do |d|
          opt[:sensus_from_file_result][d].values.each do |v|
            if v.new_record?
              if not (d == :references)
                v.proj = proj
              end
              v.written_by_ref_id = opt[:written_by_ref_id] if (d == :ontology_classes) && !opt[:written_by_ref_id].nil?
              v.save!
              proj.refs << v if (d == :references)
            end
          end
        end

        opt[:sensus_from_file_result][:sensus].each do |s|
          s.label_id = s.label.id
          s.ontology_class_id = s.ontology_class.id
          s.ref_id = s.ref.id
          s.proj_id = proj.id
        
          if not sensu = Sensu.find(:first, :conditions => {:proj_id => opt[:proj_id], :label_id => s.label_id, :ref_id => s.ref_id, :ontology_class_id => s.ontology_class_id})
            s.save!
            created_sensus.push s
          end
        end

      end
    rescue
      raise
    end

    $person_id = old_person_id
    created_sensus
  end

  def self.sensus_from_file(options = {})
    opt = {
      :file => nil,
      :proj_id => nil,
      :col_sep => "\t"
    }.merge!(options)

    raise Ontology::OntologyMethods::BatchParseError, "No file provided." if opt[:file].nil?
    raise Ontology::OntologyMethods::BatchParseError, "Project not specified." if opt[:proj_id].nil?

    recs = CSV.parse(opt[:file].read, :headers => true, :row_sep => :auto, :header_converters => nil, :col_sep => opt[:col_sep]) # reading from a string http://fastercsv.rubyforge.org/

    raise Ontology::OntologyMethods::BatchParseError, "No 'label' column header found." if !recs.headers.include?('label')
    raise Ontology::OntologyMethods::BatchParseError, "No 'reference' column header found." if !recs.headers.include?('reference')
    raise Ontology::OntologyMethods::BatchParseError, "No 'definition' column header found." if !recs.headers.include?('definition')

    labels = {}
    ontology_classes = {}
    references = {}
    sensus = []

    recs.each_with_index do |r,x|
      label, reference, ontology_class = [nil, nil, nil] 

      l = r.fields('label').first
      raise Ontology::OntologyMethods::BatchParseError, "Data row #{i} missing a value for label column." if !l
      if !labels[l]
        if label = Label.find_by_name_and_proj_id(l, opt[:proj_id])
          labels.merge!(l => label)
        else
          labels.merge!(l => (label = Label.new(:name => l)))
        end
      else
        label = labels[l]
      end
      
      # handle references 
      o = r.fields('reference').first
      raise Ontology::OntologyMethods::BatchParseError, "Data row #{i} missing a value for reference column." if !o
      if !references[o]
        if reference = Ref.find_by_cached_display_name(o) 
          references.merge!(o => reference)
        else
          reference = Ref.new(:full_citation => o)
          references.merge!(o => reference)
        end
      else
        reference = references[o]
      end

      # handle ontology_classes
      d = r.fields('definition').first
      raise Ontology::OntologyMethods::BatchParseError, "Data row #{i} missing a value for definition column." if !d
      if !ontology_classes[d]
        if ontology_class = OntologyClass.find_by_definition_and_proj_id(d, opt[:proj_id])
          ontology_classes.merge!(d => ontology_class)
        else
          ontology_class = OntologyClass.new(:definition => d, :written_by => reference)
          ontology_classes.merge!(d => ontology_class)
        end
      else
        ontology_class = ontology_classes[d]
      end

      sensus.push(Sensu.new(:ref => reference, :ontology_class => ontology_class, :label => label))
    end
    {:references => references, :labels => labels, :ontology_classes => ontology_classes, :sensus => sensus} 
  end

  # TODO REVISIT vs. class/label split
  # parses simple files like:
  #   term, option defintion 
  #   term, option defintion 
  #   ... 
  #   term, option defintion 

  def self.batch_verify_simple(opt = {})
    params = opt[:params] 

    return false if params[:temp_file][:file].blank?

    result = {:taxon_name => nil, :ref => nil, :part_for_isa => nil, :isa => nil, :terms => Turms::Turms.new} # see /lib, Turms is a utility class 

    result[:taxon_name] = TaxonName.find(params[:term][:taxon_name_id]) if params[:term] && !params[:term][:taxon_name_id].blank?
    result[:ref] = Ref.find(params[:term][:ref_id]) if params[:term] && !params[:term][:ref_id].blank?
    result[:part_for_isa] = OntologyClass.find(params[:term][:part_id_for_is_a]) if params[:term] && !params[:term][:part_id_for_is_a].blank?
    result[:isa] = ObjectRelationship.find(params[:term][:object_relationship_id]) if params[:term] && !params[:term][:object_relationship_id].blank?

    data = params[:temp_file][:file].read.split(/\n/).inject([]){|sum, l| sum << l.split(/,/, 2)}

    data.each do |t, definition|
      if @t = Label.find_by_name_and_proj_id(t.strip, opt[:proj])
        w = Turms::Turm.new(@t)
        w.definition = definition.strip if definition  # see if it matches
        result[:terms].existing.push(w) 
      else
        w = Turms::Turm.new(t)
        w.definition = definition.strip if definition
        result[:terms].not_present.push(w) 
      end
    end
    return result
  end


  # TODO: revisit vs. class/label split
  # takes :params and :proj_id
  def self.batch_create_simple(opt = {})
    params = opt[:params]

    @count = 0
    @tn = TaxonName.find(params[:taxon_name_id]) if !params[:taxon_name_id].blank?
    @ref = Ref.find(params[:ref_id]) if !params[:ref_id].blank?
    @part_for_isa = Part.find(params[:part_for_isa_id]) if !params[:part_for_isa_id].blank?
    @object_relationship = ObjectRelationship.find(params[:isa_id]) if !params[:object_relationship_id].blank?

    begin
      Part.transaction do
        for p in params[:part].keys
          if params[:check][p]

            # label
            lbl = Label.new(:name => params[:label][p])

            # class
            if params[:definition][p]
              klass = OntologyClass.new(:definition => params[:definition][p])
              klass..taxon_name = @tn if @tn
              k.ref = @ref if @ref
            end

            lbl.save!
            klass.save! if klass

            # add the relationships 
            if @object_relationship && @ontology_class_for_object_relationship
              relationship = OntologyRelationship.new(:ontology_class1_id => klass.id, :ontology_class2_id => @ontology_class_for_object_relationship.id, :object_relationship_id => @object_relationship.id )
              relationship.save!
            end


            # add the tag here
            if params[:tag] && params[:tag][:keyword_id]
              # TODO: tags go with labels or definitions, reformulate this
              raise "Code not availble for OntologClass#batch_create_simple"  
              tag = Tag.new(:keyword_id => params[:tag][:keyword_id], :addressable_type => 'Part', :addressable_id => prt.id)
              tag.notes = params[:tag][:notes] if !params[:tag][:notes].blank?
              tag.referenced_object = params[:tag][:referenced_object] if !params[:tag][:referenced_object].blank?
              tag.save!
            end

            @count += 1
          end
        end
      end

    rescue 
      return false
    end
  end

  # pass params from OntologyController#proofer_batch_create and merge proj_id => id 
  # TODO: generalize to all batch loading (from proofer, etc.)
  def self.proofer_batch_create(params)
    begin

      @proj = Proj.find(params[:proj_id])
      raise if !@proj 
      raise if params[:label].blank? 

      @count = 0
      params[:taxon_name_id] = params[:ontology_class][:highest_applicable_taxon_name_id] if params[:ontology_class] && !params[:ontology_class][:highest_applicable_taxon_name_id].blank?  # handles batch loading from Proofer
      params[:ref_id] = params[:ontology_class][:written_by_ref_id] if params[:ontology_class] && !params[:ontology_class][:written_by_ref_id].blank? # handles batch loading from Proofer

      @tn = TaxonName.find(params[:taxon_name_id]) unless params[:taxon_name_id].blank?
      @ref = Ref.find(params[:ref_id]) unless params[:ref_id].blank?
      # @part_for_isa = Part.find(params[:part_for_isa_id]) unless params[:part_for_isa_id].blank?
      # @object_relationship = ObjectRelationship.find(params[:object_relationship_id]) unless params[:object_relationship_id].blank?

      Label.transaction do
        params[:label].keys.each do |p|
          if params[:check][p]
            break if Label.find_by_name_and_proj_id(params[:label][p], @proj.id)

            lbl = Label.new(:name => params[:label][p])
            lbl.save!

            if @ref && !params[:definition][p].blank?
              oc = OntologyClass.new(:written_by => @ref, :definition => params[:definition][p], :taxon_name => @tn)
              oc.save!

              # handle xref here if code is generalized

              # linke the label to the class
              sensu = Sensu.new(:ontology_class => oc, :label => lbl, :ref => @ref)
              sensu.save! 
            end

            # this can't really happen in the split model now 
            # if @isa && @part_for_isa
            #  @relationship = Ontology.new(:part1_id => prt.id, :part2_id => @part_for_isa.id, :isa_id => @isa.id )
            #  @relationship.save!
            # end

            # add the tag here
            if !params[:tag].blank? && !params[:tag][:keyword_id].blank?
              tag = Tag.new(:keyword_id => params[:tag][:keyword_id], :addressable_type => 'Label', :addressable_id => prt.id)
              tag.notes = params[:tag][:notes] if !params[:tag][:notes].blank?
              tag.referenced_object = params[:tag][:referenced_object] if !params[:tag][:referenced_object].blank?
              tag.save!
            end

            @count += 1

          else # BACKGROUND STATS ONLY 
            te = Term.find_or_create_by_name_and_proj_id(params[:label][p], @proj.id) # BACKGROUND STATS ONLY
            te.update_attributes(:proofer_ignored => te.proofer_ignored + 1) 
          end
        end
      end

    rescue Exception => e
      raise "#{e} on #{params[:label][p]}"
    end

    return @count 
  end

  def self.ontology_classes_with_definitions_not_matching_is_a(proj_id) # :yields: Hash of OntologyClass => OntologyClass (missmatched is_a_parent)
    unmatched = Hash.new 
    Proj.find(proj_id).ontology_classes.with_populated_xref.each do |oc|
      oc.is_a_parents.each do |p|
        unmatched.merge!(oc => p) if not (oc.definition.gsub(/\AThe\s*/, '') =~ /\A#{p.preferred_label.name}/) 
      end
    end 
    unmatched
  end 

  def self.analysis_as_json(options = {})
    opt = {
      :proj_id => nil,
      :text => nil
    }.merge!(options)
    l = Linker.new(:proj_id => opt[:proj_id], :incoming_text => opt[:text], :match_type => :exact, :scrub_incoming => true) 

    h = Hash.new
    h['text'] = l.linked_text(:proj_id => opt[:proj_id], :mode => 'bracket')
    h['statistics'] = {}
    h['labels'] = {}
    l.link_set.each do |l|
      h['labels'].merge!(l.name => l.sensus.inject({}){|hsh, s| hsh.merge!(Ontology::OntologyMethods.obo_uri(s.ontology_class) => s.ref.display_name)  } )
    end 
    h     
  end

  # This is BioPortal URIs
  def self.markup_as_json(options = {})
    opt = {
      :proj_id => nil,
      :text => nil,
      :mode => 'bioportal_uri_link'  # or 'api_link'
    }.merge!(options)
    l = Linker.new(:proj_id => opt[:proj_id], :incoming_text => opt[:text], :match_type =>  :exact, :scrub_incoming => true) 

    h = Hash.new
    h['text'] = l.text_to_link # linked_text(:proj_id => opt[:proj_id])
    h['markup'] = l.linked_text(:proj_id => opt[:proj_id], :mode => opt[:mode])
    h     
  end

  def self.obo_uri(obj)
    xref = nil
    xref = obj.xref if obj.respond_to? :xref
    xref = obj.xref if obj.respond_to? :xref
    if !xref.blank?
      "http://purl.obolibrary.org/obo/" + xref.sub(/:/, "_")
    else
      nil
    end
  end

  def self.xref_from_params(id) # :yields: String (like "HAO:0123456")
    # accepts encoded URIs like http%3A%2F%2Fpurl.obolibrary.org%2Fobo%2FHAO_0000397
    # or  xref_from_params (self.uri) or id style params (like "HAO_0123456") and returns the xref form ("HAO:0123456") for database searching
    if id =~ /\Ahttp\:.*\/(.+\_.+)\Z/
      xref = $1 
    elsif id =~ /\A(.+\_.+)\Z/
      xref = $1
    else
      return false 
    end 

    return xref.gsub('_', ":") 
  end

end

end
