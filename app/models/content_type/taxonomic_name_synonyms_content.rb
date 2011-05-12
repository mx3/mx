class ContentType::TaxonomicNameSynonymsContent < ContentType
  
  def self.description
    'Synonynm for the taxonomic name attached the present OTU.'
  end

  # the partial to render, required for custom types 
  def partial
    "/otu/page/taxonomic_name_synonyms"
  end

  def self.display_name
    'Taxon name synonyms'
  end

  def display_name
   'Taxon name synonyms'
  end

  def renders_as_text?
    true
  end

end



