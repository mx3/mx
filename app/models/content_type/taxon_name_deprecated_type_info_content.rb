class ContentType::TaxonNameDeprecatedTypeInfoContent < ContentType

  def self.description
    'Contains the deprecated type info attached to the Taxon Name model (you should be using specimens!)'
  end

  # the partial to render, required for custom types
  def partial
    "/otus/page/taxon_name_deprecated_type_info"
  end

  def self.display_name
    'Type information (deprecated)'
  end

  def display_name
    'Type information (deprecated)'
  end

  def renders_as_text?
    false
  end

end
