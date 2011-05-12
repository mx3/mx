class ContentType::TagsOnOtuByKeywordContent < ContentType

  def self.description
    'A report of the tags on this OTU, organized by keyword' 
  end

  # the partial to render, required for custom types 
  def partial
    "/otu/page/tags_on_otu_by_keyword"
  end

  def self.display_name
    'Tags on this OTU'
  end

  def display_name
    'Tags on this OTU'
  end

  def renders_as_text?
    false
  end

end



