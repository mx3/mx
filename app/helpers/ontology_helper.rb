# encoding: utf-8
module OntologyHelper
  
  BUILTIN_OBO_REL_ORDER = ["is_a", "disjoint_from"]
  
  def bioportal_link_tag(ontology_class = nil,bioportal_id = nil)
    return content_tag(:em, "no xref for this class") if ontology_class.nil? || bioportal_id.nil? || ontology_class.xref.blank?
    "http://bioportal.bioontology.org/visconcepts/#{bioportal_id.to_s}/?id=#{ontology_class.xref.to_s}"
  end

  # pass an instance of OntologyClass
  # renders the def: line
  def ontology_class_definition_tag_for_OBO(ontology_class)
    return "def: \"#{ontology_class.definition.gsub(/\n/,'').strip}\" #{xrefs_for_written_by_tag_for_OBO(ontology_class.written_by, @proj)}\n" unless ontology_class.is_obsolete
    "" 
   end 
  
  # renders the synonym: lines
  def synonyms_tag_for_OBO(ontology_class)
    syns = ontology_class.obo_label.synonyms_by_ontology_class(ontology_class)
    if syns.size > 0 
      (syns.collect{|l| "synonym: \"#{l.name}\" #{xrefs_for_synonym_tag_for_OBO(l, ontology_class, @proj)}"}.join("\n")) + "\n"
    end 
  end

  # render the collective relationship lines 
  def relationship_tag_for_OBO(ontology_class)
    if !ontology_class.is_obsolete
      rels = ontology_class.primary_relationships.where_both_ontology_classes_have_xrefs
      rels.sort! {|a,b| 
        if BUILTIN_OBO_REL_ORDER.include?(a.object_relationship.interaction) and BUILTIN_OBO_REL_ORDER.include?(b.object_relationship.interaction) 
          BUILTIN_OBO_REL_ORDER.index(a.object_relationship.interaction) <=> BUILTIN_OBO_REL_ORDER.index(b.object_relationship.interaction)
        elsif BUILTIN_OBO_REL_ORDER.include?(a.object_relationship.interaction) 
          -1
        elsif BUILTIN_OBO_REL_ORDER.include?(b.object_relationship.interaction)
          1
        else
          a.object_relationship.interaction <=> b.object_relationship.interaction
        end
        }
      if rels.size > 0
        (rels.collect{|o| display_relationship_tag_for_OBO(o)}.join("\n")) + "\n"
      end
    end
  end 

  # render a single relationship: line
  def display_relationship_tag_for_OBO(ontology_relationship)
    intersection = ontology_relationship.ontology_class1.relationships_are_sufficient
    if ontology_relationship.object_relationship.interaction == "is_a"
      rel_label = intersection ? "intersection_of" : "is_a"
      "#{rel_label}: #{ontology_relationship.ontology_class2.xref} ! #{ontology_relationship.ontology_class2.obo_label.display_name}" 
    elsif ontology_relationship.object_relationship.interaction == "disjoint_from"
      "disjoint_from: #{ontology_relationship.ontology_class2.xref} ! #{ontology_relationship.ontology_class2.obo_label.display_name}"
    else
      prefix = intersection ? "intersection_of" : "relationship"
      "#{prefix}: #{ontology_relationship.object_relationship.xref} #{ontology_relationship.ontology_class2.xref} ! #{ontology_relationship.ontology_class2.obo_label.display_name}" 
    end
  end

  # renders the obsolete: line if needed 
  def obsolete_tag_for_OBO(ontology_class)
    if  ontology_class.is_obsolete
    "is_obsolete: true\n" +
    (ontology_class.is_obsolete_reason.blank? ? '' : "comment: #{ontology_class.is_obsolete_reason}\n") 
    end
  end

  # renders the xref: lines taken from Tags
  def xrefs_for_ontology_class_tag_for_OBO(ontology_class)
    xrefs = ontology_class.xrefs_from_tags
    if xrefs.size > 0
      (xrefs.collect{|x| "xref: #{x}"}.join("\n")) + "\n"
    end
  end

  # renders the xrefs for a reference, taking into account the Ontology namespace
  # may expand the namespace vs. a URI for a given installation of mx ultimately
  # TODO: remove if check on ref when data updated
  def xrefs_for_written_by_tag_for_OBO(ref = nil, proj = nil)
    return "[ERROR:ONTOLOGY_CLASS_WITHOUT_WRITTEN_BY]" if ref.nil?
    xrefs = [xref_for_ref(ref, proj)]
    return "[" + xrefs.join(", ") + "]"  # there has to be at least one
  end
  
  def xrefs_for_synonym_tag_for_OBO(synonym, ontology_class, proj)
    xrefs = synonym.sensus.by_ontology_class(ontology_class).collect{|sensu| xref_for_ref(sensu.ref, proj)}
    return "[" + xrefs.join(", ") + "]"
  end
  
  def xref_for_ref(ref, proj)
    dois = ref.identifiers.by_global_identifier_type('doi')
    if !dois.empty?
      return dois.first.cached_display_name
    else
      isbns = ref.identifiers.by_global_identifier_type('isbn')
      if !isbns.empty?
        return isbns.first.cached_display_name
      else
        uris = ref.identifiers.by_global_identifier_type('uri')
        if !uris.empty?
          return uris.first.cached_display_name
        else
          lsids = ref.identifiers.by_global_identifier_type('lsid')
          if !lsids.empty?
            return lsids.first.cached_display_name
          else
            xrefs = ref.identifiers.by_global_identifier_type('xref')
            if !xrefs.empty?
              return xrefs.first.cached_display_name
            else
              return "http://" + proj.api_name + "/api/ref/" + ref.id.to_s
            end
          end
        end
      end
    end
  end

  # renders the collective [Typdef] tags 
  def typedefs_tag_for_OBO(proj)
    typedefs = proj.object_relationships.not_builtin
    if typedefs.size > 0
      typedefs.collect{|i| typedef_tag_for_OBO(i)}.join("\n") 
    end
  end

  # renders a single [Typedef] tag
  def typedef_tag_for_OBO(object_relationship)
   s =  "[Typedef]\n"
   s += "id: #{object_relationship.xref}\n"
   s += "name: #{object_relationship.interaction}\n"
   s += "is_transitive: true\n" if object_relationship.is_transitive
   s += "is_reflexive: true\n" if object_relationship.is_reflexive
   s += "is_anti_symmetric: true\n" if object_relationship.is_anti_symmetric
   s
   #s += "xref: #{object_relationship.xref}\n" if !object_relationship.xref.blank?
  end
  
  def obo_uri(obj)
    #TODO convert all uses of this helper method to the lib method? the lib method is needed because the URIs are created in non-view code sometimes
    Ontology::OntologyMethods.obo_uri(obj)
  end
  
  def escape_double_quotes(text)
    text.gsub(/"/, '\"')
  end

end
