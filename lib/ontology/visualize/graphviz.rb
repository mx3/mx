
module Ontology::Visualize::Graphviz

  def self.dot(options = {})
   g = GraphViz.new( :G, :type => :digraph)

   Proj.find(options[:proj_id]).ontology_relationships(:include => [:ontology_class1, :ontology_class2, :object_relationship]).by_object_relationship_name('attached_to').each do |o|
      one = g.add_node( o.ontology_class1_id.to_s, "label" => o.ontology_class1.preferred_label.name )
      two = g.add_node( o.ontology_class2_id.to_s, "label" => o.ontology_class2.preferred_label.name )

      # Create an edge between the two nodes
      g.add_edge( one, two, "label" => o.object_relationship.interaction, "color" =>  Ontology::Visualize::Graphviz.relationship_color_map(o.object_relationship.interaction)  )
   end
    g   
  end

  def self.relationship_color_map(relationship)
    color_map = {'is_a' => 'red', 'part_of' => 'blue', 'attached_to' => 'green', 'integral_part_of' => 'orange'}
    color = color_map[relationship]
    color ? color : 'gray'
  end

end

