class ContentType::ReferencedDistributionNativeContent < ContentType

  def self.description
    'A summary of the distribution of this OTU as tied to published references (not directly through specimen records), includes native, non-native, and undetermined categories.'
  end

  # the partial to render, required for custom types 
  def partial
    "/otu/page/referenced_distribution_native"
  end

  def self.display_name
    'Referenced distribution (native/introduced)'
  end

  def display_name
    'Referenced distribution (native/introduced)'
  end

  def render_as_text?
    true
  end


end



