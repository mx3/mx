# encoding: utf-8
module PublicContentHelper

  # both required, not used at present 
  def link_to_content_by_tn_section(by_tn_section, content_template_id = nil)
    return 'misconfigured, provide a content_template_id' if content_template.nil? || by_tn_section.nil?
    link = (link_to(by_tn_section.header.name, :action => :show, :controller => '/public/public_content', :id => by_tn_section.items.first.id, :content_template_id => content_template_id) + " " + by_tn_section.header.display_author_year).strip
    if by_tn_section.items.size > 1
      i = 0 
      alternates = []
      by_tn_section.items[1..by_tn_section.items.size].each do |i|
        alternates << link_to("alternate page #{i}", :action => :show, :controller => '/public/public_content', :id => i.id, :content_template_id => content_template_id) 
        i += 1
      end
      link + alternates.join(", ")
    end
    link
  end

  # tricky formatting
  def otu_to_content_link(otu, content_template_id = nil)
    str = '<strong>' 
    link_txt = ''
    
    if otu.taxon_name
      if otu.taxon_name.italicize?
        link_txt = content_tag(:em,otu.taxon_name.name)
      else
        link_txt = otu.taxon_name.name
      end
    else
      link_txt = otu.name 
    end

    # link or not
    if otu.has_public_content?
      str += link_to(link_txt, :action => :show, :controller => '/public/public_content', :id => otu.id, :content_template_id => content_template_id)
    else
      str += link_txt 
    end
    
    str += '</strong>'

    # append if necessary
    if otu.taxon_name
       str += "&nbsp;" + otu.taxon_name.display_author_year
    end

    str
  end

end
