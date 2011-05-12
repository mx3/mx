# encoding: utf-8
module LabelHelper

  def label_name_with_activity_heatmap(label)
    content_tag(:span, label.name, :style => "padding:2px; color:#232323;background-color:##{ColorHelper::palette(:palette => :heat_10, :index => (label.active_index || 0), :hex => true)[2..7]}")
  end

  def brief_activity_report(label)
    [content_tag(:span, label.activator.first_name), content_tag(:span, label.active_msg),
    link_to(label.display_name, :action => :show, :id => label, :controller => :label),  time_ago_in_words(label.active_on) + " ago."].join(" ")
  end

  def brief_activity_report_string(label)
    [label.activator.first_name, label.active_msg, label.display_name,  time_ago_in_words(label.active_on) + " ago."].join(" ")
  end

  def is_defined_tag(l)
    if l.ontology_classes.size > 0
        content_tag('span', l.ontology_classes.size, :class => 'passed', :style => 'padding: 2px;')
    else
        content_tag('span', "-", :class => 'failed', :style => 'padding: 2px;')      
    end
  end
   
  # TODO: clever routing in rails 3
  def destroy_label_link_tag(label, person)
    if person.is_ontology_admin && !(label.ontology_classes.with_populated_xref.size > 0) 
      link_to('Destroy', {:action => 'destroy', :id => label.id}, :method => "post", :confirm => "Are you sure you want to destroy this label?") 
    end 
  end

    
end
