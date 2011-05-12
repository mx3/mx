class ContentType::PublicImagesContent < ContentType

  def self.description
    'All the images attached to this OTU that are checked as public.'
  end

  # the partial to render, required for custom types 
  def partial
    "/otu/page/public_images"
  end

  def self.display_name
    'Public images'
  end

  def name
    'Public images'
  end

  def display_name
    "Public images"
  end


end

