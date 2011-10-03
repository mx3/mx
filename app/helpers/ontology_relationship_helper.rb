# encoding: utf-8
module OntologyRelationshipHelper

  def ontology_relationship_link_for_show(params = {})
    opts = {
      :div_id => 'new_ontology_relationship'
    }.merge!(params)

    content_tag :div, link_to("Add relationship", :remote => true, :url =>  opts.merge(:action => :new, :controller => :ontology_relationship, 'ontology_relationship[ontology_class1_id]' => opts[:ontology_class_id])), :id => opts[:div_id]
  end

end
