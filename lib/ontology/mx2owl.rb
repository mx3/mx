module Ontology::Mx2owl

  CDAO_TU = "http://www.evolutionaryontology.org/cdao/1.0/cdao.owl#TU"
  CDAO_CHARACTER = "http://www.evolutionaryontology.org/cdao/1.0/cdao.owl#Character"
  CDAO_STATE = "http://www.evolutionaryontology.org/cdao/1.0/cdao.owl#CharacterStateDomain"
  CDAO_CELL = "http://www.evolutionaryontology.org/cdao/1.0/cdao.owl#CharacterStateDatum" #check IRI
  CDAO_BELONGS_TO_CHARACTER = "http://www.evolutionaryontology.org/cdao/1.0/cdao.owl#belongs_to_Character"
  CDAO_BELONGS_TO_TU = "http://www.evolutionaryontology.org/cdao/1.0/cdao.owl#belongs_to_TU"
  CDAO_HAS_STATE = "http://www.evolutionaryontology.org/cdao/1.0/cdao.owl#has_State"
  CAN_HAVE_STATE = "http://purl.oclc.org/NET/mx-database/can_have_state"
  HAS_MX_ID = "http://purl.oclc.org/NET/mx-database/has_mx_id"
  DESCRIBES_STATE = "http://purl.oclc.org/NET/mx-database/describes_state"
  BEARER_OF = "http://purl.obolibrary.org/obo/OBO_REL_bearer_of"
  TOWARDS = "http://purl.obolibrary.org/obo/OBO_REL_towards"
  HAS_PART = "http://purl.obolibrary.org/obo/OBO_REL_has_part"
  HAS_COMPONENT_PART = "http://vocab.phenoscape.org/has_component_part"
  POSITED_BY = "http://vocab.phenoscape.org/posited_by"
  
  def self.translate_coding(coding, owl)
    coding_node = coding_node(coding)
    cdao_cell = owl.named_class(CDAO_CELL)
    owl.class_assertion(cdao_cell, coding_node)
    owl.property_assertion(RDF::RDFS.label, coding_node, coding.display_name)
    has_mx_id = owl.annotation_property(HAS_MX_ID)
    owl.property_assertion(has_mx_id, coding_node, coding.id)
    chr_state_node = chr_state_node(coding.chr_state)
    chr_node = chr_node(coding.chr)
    otu_node = otu_node(coding.otu)
    belongs_to_character = owl.object_property(CDAO_BELONGS_TO_CHARACTER)
    owl.property_assertion(belongs_to_character, coding_node, chr_node)
    belongs_to_tu = owl.object_property(CDAO_BELONGS_TO_TU)
    owl.property_assertion(belongs_to_tu, coding_node, otu_node)
    has_state = owl.object_property(CDAO_HAS_STATE)
    owl.property_assertion(has_state, coding_node, chr_state_node)
    if coding.chr_state.phenotype
      phenotype_class = phenotype_node(coding.chr_state.phenotype, owl)
      class_assertion_statement = owl.class_assertion(phenotype_class, otu_node)
      posited_by = owl.annotation_property(POSITED_BY)
      owl.axiom_annotation(class_assertion_statement, posited_by, coding_node)
    end
  end
  
  def self.translate_otu(otu, owl)
    node = otu_node(otu)
    cdao_tu = owl.named_class(CDAO_TU)
    owl.class_assertion(cdao_tu, node)
    owl.property_assertion(RDF::RDFS.label, node, otu.display_name)
    has_mx_id = owl.annotation_property(HAS_MX_ID)
    owl.property_assertion(has_mx_id, node, otu.id)
    return node
  end
  
  def self.translate_chr(chr, owl)
    node = chr_node(chr)
    cdao_character = owl.named_class(CDAO_CHARACTER)
    owl.class_assertion(cdao_character, node)
    owl.property_assertion(RDF::RDFS.label, node, chr.display_name)
    has_mx_id = owl.annotation_property(HAS_MX_ID)
    owl.property_assertion(has_mx_id, node, chr.id)
    chr.chr_states.each do |state|
      can_have_state = owl.object_property(CAN_HAVE_STATE)
      owl.property_assertion(can_have_state, node, chr_state_node(state))
      translate_chr_state(state, owl)
    end
    return node
  end
  
  def self.translate_chr_state(chr_state, owl)
    node = chr_state_node(chr_state)
    cdao_state = owl.named_class(CDAO_STATE)
    owl.class_assertion(cdao_state, node)
    owl.property_assertion(RDF::RDFS.label, node, chr_state.display_name)
    has_mx_id = owl.annotation_property(HAS_MX_ID)
    owl.property_assertion(has_mx_id, node, chr_state.id)
    if chr_state.phenotype
      describes_state = owl.annotation_property(DESCRIBES_STATE)
      owl.property_assertion(describes_state, phenotype_node(chr_state.phenotype, owl), node)
      translate_phenotype(chr_state.phenotype, owl)
    end
    return node
  end
  
  def self.translate_phenotype(mx_phenotype, owl)
    phenotype = phenotype_node(mx_phenotype, owl)
    has_mx_id = owl.annotation_property(HAS_MX_ID)
    owl.property_assertion(has_mx_id, phenotype, mx_phenotype.id)
    self.send("translate_" + mx_phenotype.class.to_s.underscore, mx_phenotype, phenotype, owl)
  end
  
  def self.translate_qualitative_phenotype(mx_phenotype, phenotype, owl)
    if (mx_phenotype.entity == nil) || (mx_phenotype.quality == nil)
      return phenotype
    end
    quality_term = translate_ontology_class(mx_phenotype.quality, owl)
    if mx_phenotype.dependent_entity
      dependent_entity = translate_ontology_class(mx_phenotype.dependent_entity, owl)
      towards = owl.object_property(TOWARDS)
      quality = quality_term.and(towards.some(dependent_entity))
    else
      quality = quality_term
    end
    entity = translate_ontology_class(mx_phenotype.entity, owl)
    bearer_of = owl.object_property(BEARER_OF)
    has_part = owl.object_property(HAS_PART)
    owl.equivalent_classes(phenotype, has_part.some(entity.and(bearer_of.some(quality))))
    return phenotype
  end
  
  def self.translate_presence_absence_phenotype(mx_phenotype, phenotype, owl)
    if mx_phenotype.entity == nil
      return phenotype
    end
    entity = translate_ontology_class(mx_phenotype.entity, owl)
    has_part = owl.object_property(HAS_PART)
    if mx_phenotype.is_present
      has_entity_class = has_part.some(entity)
    else
      has_entity_class = has_part.only(owl.not(entity))
    end
    if mx_phenotype.within_entity
      within_entity = translate_ontology_class(mx_phenotype.within_entity, owl)
      owl.equivalent_classes(phenotype, has_part.some(within_entity.and(has_entity_class)))
    else
      owl.equivalent_classes(phenotype, has_entity_class)
    end
    return phenotype
  end
  
  def self.translate_count_phenotype(mx_phenotype, phenotype, owl)
    if (mx_phenotype.entity == nil) || (mx_phenotype.minimum == nil && mx_phenotype.maximum == nil)
      return phenotype
    end
    entity = translate_ontology_class(mx_phenotype.entity, owl)
    has_component_part = owl.object_property(HAS_COMPONENT_PART)
    if mx_phenotype.minimum != nil
      if mx_phenotype.minimum == mx_phenotype.maximum
        has_entity_class = has_component_part.exactly(mx_phenotype.minimum, entity)
      elsif mx_phenotype.maximum != nil
        has_entity_class = (has_component_part.min(mx_phenotype.minimum, entity)).and(has_component_part.max(mx_phenotype.maximum, entity))
      else
        has_entity_class = has_component_part.min(mx_phenotype.minimum, entity)
      end
    else
      has_entity_class = has_component_part.max(mx_phenotype.maximum, entity)
    end
    if mx_phenotype.within_entity
      has_part = owl.object_property(HAS_PART)
      within_entity = translate_ontology_class(mx_phenotype.within_entity, owl)
      owl.equivalent_classes(phenotype, has_part.some(within_entity.and(has_entity_class)))
    else
      owl.equivalent_classes(phenotype, has_entity_class)
    end
    return phenotype
  end
  
  def self.translate_ontology_class(term, owl)
    if term.class == OntologyComposition
      translate_ontology_composition_class(term, owl)
    else
      translate_ontology_term_class(term, owl)
    end
  end
  
  def self.translate_ontology_term_class(term, owl)
    node = owl.named_class(term.uri)
    if (term.label)
      owl.property_assertion(RDF::RDFS.label, node, term.label)
    end
    return node
  end
  
  def self.translate_ontology_composition_class(term, owl)
    if !term.genus
      return nil
    end
    if term.differentiae.empty?
      return translate_ontology_class(term.genus, owl)
    end
    operands = []
    operands << translate_ontology_class(term.genus, owl)
    term.differentiae.each do |differentia|
      operands << translate_ontology_differentia(differentia, owl)
    end
    intersection = owl.intersection_of(operands)
    return intersection
  end
  
  def self.translate_ontology_differentia(differentia, owl)
    has_property = translate_ontology_property(differentia.property, owl)
    filler = translate_ontology_class(differentia.value, owl)
    has_property.some(filler)
  end
  
  def self.translate_ontology_property(term, owl)
    node = owl.object_property(term.uri)
    if term.label
      owl.property_assertion(RDF::RDFS.label, node, term.label)
    end
    return node
  end

  def self.class_depictions(proj)
    raise if proj.nil?
    terms = proj.ontology_classes.with_xref_namespace(proj.ontology_namespace).with_obo_label.ordered_by_xref
    graph = RDF::Graph.new
    owl = OWL::OWLDataFactory.new(graph)
    prefix = "http://#{proj.api_name}/api/figure/"
    depicts = owl.object_property("http://xmlns.com/foaf/0.1/depicts")
    owl.property_assertion(RDF::RDFS.label, depicts, "depicts")
    image = owl.named_class("http://xmlns.com/foaf/0.1/Image")
    owl.property_assertion(RDF::RDFS.label, image, "Image")
    terms.each do |term|
      figures = term.figures.with_figure_markers
      if !figures.empty?
        term_uri = Ontology::OntologyMethods.obo_uri(term)
        term_class = owl.named_class(term_uri)
        figures.each do |figure|
          figure_uri = prefix + "#{figure.id}.svg"
          figure_ind = RDF::URI(figure_uri)
          owl.class_assertion(image, figure_ind)
          owl.class_assertion(depicts.some(term_class), figure_ind)
        end
      end
    end
    RDF::RDFXML::Writer.buffer {|writer| writer << graph}
  end 
  
  private
  
  def self.chr_node(chr)
    RDF::URI.new("Chr_" + chr.id.to_s)
  end
  
  def self.chr_state_node(chr_state)
    RDF::URI.new("ChrState_" + chr_state.id.to_s)
  end
  
  def self.phenotype_node(phenotype, owl)
    owl.named_class("Phenotype_" + phenotype.id.to_s)
  end
  
  def self.otu_node(otu)
    RDF::URI.new("OTU_" + otu.id.to_s)
  end
  
  def self.coding_node(coding)
    RDF::URI.new("Coding_" + coding.id.to_s)
  end
  
end
