class ContentType::GmapContent < ContentType

  def self.description
    'A Google map.  Includes all specimens with the current determination of the given OTU.'
  end

  def self.display_name
    "Google map"
  end

  # the partial to render, required for custom types 
  def partial
    "/otu/page/gmap"
  end

  def display_name
    "Google map"
  end

  def renders_as_text?
    false
  end


end

