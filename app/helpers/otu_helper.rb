# encoding: utf-8
module OtuHelper

  # TODO: This isn't used anywhere yet.
  def otu_fancy_name_tag(otu)
    s = ''
    s << content_tag(:span, otu.taxon_name.display_name(:type => :fancy_name), :class => :otu_taxon_name) if otu.taxon_name
    s << content_tag(:span, otu.name, :class => :otu_name) if otu.name  
    s << content_tag(:span, otu.manuscript_name, :class => :otu_manuscript_name) if otu.manuscript_name  
    s << content_tag(:span, otu.matrix_name, :class => :otu_matrix_name) if otu.matrix_name  
    s
  end

end
