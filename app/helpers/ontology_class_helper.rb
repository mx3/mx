# encoding: utf-8
module OntologyClassHelper
  
  def ontology_class_postfixed_with_label(oc, id_match = nil)
    link_to(oc.definition.blank? ? content_tag(:em, 'no definition provided') : oc.definition, :action => :show, :id => oc.id, :controller => :ontology_class) + "&nbsp;" +
     content_tag(:span, :style => "padding: 2px; background-color: #ddd; color:gray;") do
      if oc.id == id_match
        content_tag(:span, oc.label_name(:type => :preferred), :style => "padding: 1px;", :class => "highlight")
      else
        content_tag(:span, oc.label_name(:type => :preferred), :style => "padding: 1px; background-color:#b5ebc7;")
      end    
    end
  end
  
  def labels_banner_tag(oc)
    return content_tag(:em, 'no labels attached to this class') if oc.labels.size == 0
    content_tag :span, oc.labels.ordered_by_name.collect{|l| content_tag(:span, link_to(l.name, :action => :show, :controller => :label, :id => l), :style => label_style(oc, l)) }.join(", "), :style => 'font-size: larger;'
  end

  def public_labels_banner_tag(oc)
    synonyms =  oc.preferred_label.synonyms_by_ontology_class(oc)
    s = content_tag(:span, oc.label_name(:type => :preferred), :style => 'font-size:150%') 
    if synonyms.size > 0 
     s +=  content_tag(:span, :style => 'color:#888; ') do 
        ' synonyms: ' + content_tag(:span, synonyms.collect{|l| link_to(l.name, :action => :show, :controller => :label, :id => l.id)}.join(", "))
      end
    end
    s
  end

  def public_relationships_banner_tag(options = {})
    opt = {
      :ontology_class => nil,
      :type => :is_a_parents  
    }.merge!(options)

    return nil if opt[:ontology_class].nil?

    result = []

    case opt[:type]
    when :is_a_parents, :is_a_children, :part_of_ancestors, :is_a_ancestors, :is_a_descendants
      result = opt[:ontology_class].send(opt[:type])
    when :part_of_parents
      result = opt[:ontology_class].parents_by_relationship('part_of')
    when :part_of_children
      result = opt[:ontology_class].children_by_relationship('part_of')
    when :attached_to_children
      result = opt[:ontology_class].children_by_relationship('attached_to')
    when :attached_to_parents
      result =  opt[:ontology_class].parents_by_relationship('attached_to')
    else
      return nil
    end 

    result.uniq!

    case result.size
    when 0
      return content_tag(:em, 'none')    
    else
      result.sort!{|a, b| a.preferred_label.name <=> b.preferred_label.name}.collect{|r| link_to(r.preferred_label.name, :id => r.id, :action => :show_expanded)}.join(", ") 
    end
  end

  def label_style(oc, l)
     s = ''
     s += "border-bottom: 2px dotted red;"  if oc.label_name(:type => :top_sensu) == l.name  # "preferred"
     s += "background: #BEBADA;" if oc.obo_label && oc.obo_label.name == l.name              # "currently on"
     s += "border-top: 2px dotted #b5ebc7;" if oc.label_name(:type => :oldest) == l.name     # "oldest"
     s
  end

  def obo_label_tag(oc)
      (oc.obo_label.blank? ? '-' : oc.obo_label.display_name)
  end

  # TODO: clever routing in rails 3
  def destroy_ontology_class_link_tag(oc, person)
   if person.is_ontology_admin && oc.xref.blank? 
	   link_to('Destroy', {:action => 'destroy', :id => oc.id}, :method => "post", :confirm => "Are you sure you want to destroy this ontology class?") 
   end 
  end

  # TODO: clever rails 3 routing
  def add_xref_to_ontology_class_tag(oc, person)
    if person.is_ontology_admin && oc.xref.blank? && !oc.obo_label_id.blank? 
       link_to('Generate xref', {:action => 'generate_xref', :id => oc.id}, :method => "post", :confirm => "Classes with xrefs can not be deleted. Are you sure you want to generate a xref for this ontology class?") 
     end 
  end

  def OBO_def_tag(ontology_class)
	  "def: \"#{ontology_class.clean_description_display}\" #{ontology_class.obo_xref_for_ref}<br />" if !ontology_class.description.blank? 
  end

  def MB_link_tag(options = {})
    opt = {
      :ontology_class => nil,
      :taxon => nil,
      :overide_taxon => false
    }.merge!(options)

    return '' if opt[:ontology_class].blank? 
    opt[:taxon] = opt[:ontology_class].taxon_name.name if opt[:overide_taxon] && !opt[:ontology_class].taxon_name.blank? # if the part has a specified taxon use that

    #    http://www.morphbank.net/Browse/ByImage/?keywords=head+Hymenoptera&tsnKeywords=&spKeywords=&viewKeywords=&localityKeywords=&listField1=imageId&orderAsc1=DESC&listField2=&orderAsc2=ASC&listField3=&orderAsc3=ASC&numPerPage=20&resetOffset=&activeSubmit=1&tsnId_Kw=keywords&viewId_Kw=keywords&spId_Kw=keywords&localityId_Kw=keywords&offset=0&log=NO&log=NO
    #
    kw_str = [opt[:taxon], opt[:ontology_class].labels.first.display_name].compact.join("+")
    s = 'http://www.morphbank.net/Browse/ByImage/index.php?'
    s << "keywords=#{kw_str}"
    s << "&tsnKeywords=&spKeywords=&viewKeywords=&localityKeywords=&listField1=imageId&orderAsc1=DESC&listField2=&orderAsc2=ASC&listField3=&orderAsc3=ASC&numPerPage=20&resetOffset=&activeSubmit=1&tsnId_Kw=keywords&viewId_Kw=keywords&spId_Kw=keywords&localityId_Kw=keywords&offset=0&log=NO&log=NO"
  end

  # TODO: this is being used, clarify it (broken in helper)
  def xref_tags_display_tag(ontology_class, xref_keyword)
    return "ERROR" if !xref_keyword || !ontology_class
    t = ""
    t = ontology_class.tags.by_keyword(xref_keyword).collect{|x| !x.referenced_object.blank? ? "xref: #{x.referenced_object}" : nil}.compact.join("<br />")
    t.size > 0 ? "#{t}<br />" : ""
   end
 
  #move to helper with _tag 
  def obo_xref_for_ref_tag(ontology_class)
    return "[mxOBO:needs_xref]" if !ontology_class.ref
    ontology_class.ref.db_xref_list
  end
 
  # moved to helper with _tag 
  def db_xref_REF_for_ref_tag(ontology_class)
      return "" if !ontology_class.ref
      ontology_class.ref.db_xref_REF_list
  end

  def bioportal_link_tag(ontology_class, bioportal_version_id)
    if bioportal_id != ""
      if xref
        "http://bioportal.bioontology.org/visconcepts/#{bioportal_version_id.to_s}/?id=#{ontology_class.xref.to_s}"
      else
        false
      end
    end
  end

  # TODO: recode/revisit with label.display_name
  # should likely be in OntologyHelper
  def bioportal_link_display_name_tag(ontology_class, bioportal_id)
    if bioportal_id != ""
      if xref
        "<td><strong>#{ontology_class.obo_label.display_name}</strong>,</td><td>#{bioportal_link_tag(ontology_class, bioportal_id)}</td>"
      end
    end
  end


end
