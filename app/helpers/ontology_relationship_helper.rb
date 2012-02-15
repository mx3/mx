# encoding: utf-8
module OntologyRelationshipHelper

  def ontology_relationship_link_for_show(params = {})
    opts = {
      :div_id => 'new_ontology_relationship'
    }.merge!(params)

    content_tag :div,
      link_to("Add relationship",
          opts.merge(:action => :new, :controller => :ontology_relationships, 'ontology_relationship[ontology_class1_id]' => opts[:ontology_class_id]),
          {'data-ajaxify'=>'modal'}),
        :id => opts[:div_id]
  end

end
