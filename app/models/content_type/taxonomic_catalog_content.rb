class ContentType::TaxonomicCatalogContent < ContentType

  def self.description
    'A taxonomic history formatted catalog-style for print. Does not display a header.' 
  end

  # the partial to render, required for custom types 
  def partial
    "/otu/page/taxonomic_catalog"
  end

  def self.display_name
    'Taxonomic catalog'
  end

  def display_name
   'Taxonomic catalog'
  end

  def renders_as_text?
    true
  end

  def render_header?
    false
  end

end



