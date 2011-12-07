# encoding: utf-8
module ContentHelper

  # content_for is Rails reserved, to be used with :yield
  def text_content_for(otu = nil, intro_content_type = nil, is_public = false)
   if c = Content.find_by_otu_id_and_content_type_id(otu.id, intro_content_type.id)
      content_tag(:div, render_content(:text => c.text), :style => 'clear:both; padding:0.5em')
   else
     content_tag(:em, 'none')
   end
  end

  # links the text between tags as below to their respective instances 
  # <otu id="234"> </otu> 
  def link_otus(options = {})
    opt = {
      :text => '',
      :public => false,
      :content_template_id => nil
    }.merge!(options)
    if opt[:text]["<otu"]
      opt[:text].gsub(/<otu\s+id=\"(\d+)\">(.+?)<\/otu>/) {|s| link_to($2, :controller => (opt[:public] ? 'public/public_contents' : :otus ), :action => 'show', :id => $1, :content_template_id => opt[:content_template_id])}
    else
      opt[:text]
    end
  end

  # links the text between tags as below to their respective instances 
  # <ref id="234"> </ref> 
  def link_refs(options = {})
    opt = {
      :text => '',
      :public => false,
      :content_template_id => nil
    }.merge!(options)
    
   # was [^+<]+ 
    if opt[:text]["<ref"]
      opt[:text].gsub(/<ref\s+id=\"(\d+)\">(.+?)<\/ref>/) {|s| link_to($2, :controller => :refs, :action => :show, :id => $1, :content_template_id => opt[:content_template_id])}
    else
      opt[:text]
    end
  end

  # chains all link_ methods
  def tags_to_links(options = {})
    opt = {
          :text => '',
          :public => false,
          :content_template_id => nil
        }.merge!(options)
#        link_refs(opt)
   link_otus(
     opt.merge!(:text => link_refs(opt))
   )
  end 


  # Redcloth plus all link_ methods
  def render_content(options = {})
    opt = {
          :text => '',
          :public => false,
          :content_template_id => nil
        }.merge!(options)
    txt = htmlize(opt[:text])
   
    # htmlize sucks at some things
   txt.gsub!('</ref> <p>', '</ref> ')     # hack fix for text starting with <ref>
   txt.gsub!(/\A<p>|<\/p>\Z/, '')         # strip paragraph markers
   tags_to_links(opt.merge!(:text => txt.strip))
  end

end
