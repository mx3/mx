class ContentType::SpecimensContent < ContentType

  def self.description
    'A specimen table. Includes all specimens with the current determination of the given OTU.'
  end

  # the partial to render, required for custom types
  def partial
    "/otus/page/specimens"
  end

  def self.display_name
    "Specimen content"
  end

  def display_name
    "Specimen content"
  end

  def renders_as_text?
    true
  end

end
