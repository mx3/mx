class ContentType::TaxonomicHistoryContent < ContentType

  def self.description
    'A header including the taxonic history for the taxonomic name attached to this OTU.'
  end

  # the partial to render, required for custom types 
  def partial
    "/otu/page/taxonomic_history"
  end

  def self.display_name
    'Taxonomic history header'
  end

  def display_name
   'Taxonomic history header'
  end

  def render_as_text?
    true
  end

end



