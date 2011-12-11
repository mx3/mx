class ContentType::TaxonNameHeaderContent < ContentType

  def self.description
    'A header including the taxon/OTU name and author year.'
  end

  # the partial to render, required for custom types
  def partial
    "/otus/page/taxon_name_header"
  end

  def self.display_name
    'Taxon name header'
  end

  def display_name
   'Taxon name header'
  end

  def renders_as_text?
    true
  end

  def render_header?
    false
  end

end
