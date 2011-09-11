# encoding: utf-8
module ImageDescriptionHelper

  # Compute cell, with css, to display in the table
  def image_description_cell_status(otu_id, std_view) 
    img_descrs = std_view.image_descriptions_by_otu_id(otu_id)
    if img_descrs.size > 0
      return content_tag(:td, render(:partial => 'image_description/id', :collection => img_descrs))
    else  # No images are found for this otu/view combination      
      return content_tag(:td, 'none', :class => 'failed') 
    end
  end

  def image_description_taxon_tag(image_description)
    if image_description.specimen && image_description.specimen.most_recent_determination
      image_description.specimen.most_recent_determination.display_name
    elsif image_description.otu 
      image_description.otu.display_name
    else
      content_tag(:em, 'none')
    end
  end
    
end
