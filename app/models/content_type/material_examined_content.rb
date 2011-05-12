class ContentType::MaterialExaminedContent < ContentType

  def self.description
    'A formatted material examined section as one would use for publication.  Specimens only.'
  end

  # the partial to render, required for custom types 
  def partial
    "/otu/page/material_examined"
  end

  def self.display_name
    'Material examined'
  end

  def display_name
   'Material examined'
  end

  def renders_as_text?
    true
  end

  def render_header?
    false
  end

end



