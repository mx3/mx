class ContentType::ReferencedDistributionContent < ContentType


  def self.description
    'A summary of the distribution of this OTU as tied to published references (not directly through specimen records).'
  end

  # the partial to render, required for custom types
  def partial
    "/otus/page/referenced_distribution"
  end

  def self.display_name
    'Referenced distribution'
  end

  def display_name
   'Referenced distribution'
  end

  def renders_as_text?
    true
  end
end
