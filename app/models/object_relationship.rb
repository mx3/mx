class ObjectRelationship < ActiveRecord::Base
  has_standard_fields  

  acts_as_list :scope => :proj
  belongs_to :proj
  has_many :association_parts
  ## validates_uniqueness_of (:interaction, :complement) , :scope => 'proj_id' # need combination of these

  # all the isas used in ontologies where part2_id is used
  # scope :by_child_part, lambda {|*args|  {:conditions => ["isas.id IN (SELECT isa_id from ontologies where part2_id = ?)", args.first || -1] }} 
    
  scope :with_color_set, {:conditions => 'html_color IS NOT null AND html_color != ""'}
  scope :not_isa, {:conditions => "interaction != 'is_a'"}
  scope :not_builtin, {:conditions => "interaction NOT IN ('is_a', 'disjoint_from')"}
  scope :by_interaction, lambda {|*args| {:conditions => ["interaction = ?",  (args.first || -1)]}}
  scope :ontology_relations, {:conditions => "(xref IS NOT null) AND (xref != '')"}

  validates_presence_of :interaction

  def display_name(options = {})
    "#{interaction} / #{complement}"
  end

  # TODO deprecate, xml or helper or display_name
  def colored_display_name
    html_color.blank? ? "#{interaction} / #{complement}": "<div style=\"display: inline; background: ##{html_color}; padding: 0px .2em;\">#{interaction} / #{complement}</div>"  
  end

  def object_relationship_link_for_show(params = {})
    opts = {
      :div_id => 'new_object_relationship'
    }.merge!(params)

    content_tag :div, link_to("Add relationship", :url =>  opts.merge(:action => :new, :controller => :object_relationship), :remote => true ), :id => opts[:div_id]
  end

  def as_json
    {'id' => Ontology::OntologyMethods.obo_uri(self), 'name' => interaction}
  end

end
