# encoding: utf-8
module PhenotypeHelper
  
  def manchester_phenotype(phenotype)
    if phenotype.kind_of? QualitativePhenotype
      quality = phenotype.dependent_entity ? "(#{html_ontology_value(phenotype.quality)} and towards some #{html_ontology_value(phenotype.dependent_entity)})" : html_ontology_value(phenotype.quality)
        "has_part some (#{html_ontology_value(phenotype.entity)} and bearer_of some #{quality})"
    elsif phenotype.kind_of? PresenceAbsencePhenotype
      value = phenotype.is_present? ? "some" : "exactly 0"
      cardinality = "has_part #{value} #{html_ontology_value(phenotype.entity)}"
      if phenotype.within_entity
        "has_part some (#{html_ontology_value(phenotype.within_entity)} and #{cardinality})"
      else
        cardinality
      end
    elsif phenotype.kind_of? CountPhenotype
      cardinalities = []
      if phenotype.minimum == phenotype.maximum
        cardinalities << "has_part exactly #{phenotype.minimum} #{html_ontology_value(phenotype.entity)}"
      else
        if phenotype.minimum
          cardinalities << "has_part min #{phenotype.minimum} #{html_ontology_value(phenotype.entity)}"
        end
        if phenotype.maximum
          cardinalities << "has_part max #{phenotype.maximum} #{html_ontology_value(phenotype.entity)}"
        end
      end
      cardinality = cardinalities.join(" and ")
      if phenotype.within_entity
        "has_part some (#{html_ontology_value(phenotype.within_entity)} and #{cardinality})"
      else
        cardinality
      end
    elsif phenotype.kind_of? RelativePhenotype
      desc = "has_part some (#{html_ontology_value(phenotype.entity)} and bearer_of some (#{html_ontology_value(phenotype.quality)} and #{phenotype.relative_magnitude} some (#{html_ontology_value(phenotype.relative_quality)} and inheres_in some #{html_ontology_value(phenotype.relative_entity)})))"
      if phenotype.relative_proportion.blank?
        desc
      else
        desc + ", proportion: #{phenotype.relative_proportion.to_s}"
      end
    end
  end
  
  def html_ontology_value(value)
    return '<span>?</span>' if !value
    value.kind_of?(OntologyTerm) ? html_ontology_term(value) : html_ontology_composition(value)
  end
  
  def html_ontology_term(term)
    link_to term.label, term.uri, :target => "_blank"
  end
  
  def html_ontology_composition(term)
    #TODO this is temporary
    pieces = []
    pieces << html_ontology_value(term.genus) if term.genus
    pieces << term.differentiae.collect{|diff| html_differentia(diff) }
    %'(#{pieces.join(" and ")})'
  end
  
  def html_differentia(diff)
    %'#{html_ontology_term(diff.property)} some #{html_ontology_value(diff.value)}'
  end
  
end
