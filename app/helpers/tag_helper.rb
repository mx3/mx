# encoding: utf-8
module TagHelper

  def tag_class(tag)
    "tag-class-#{tag.id}"
  end

  def new_tag_tag(options ={})
    opt = {
      :object => nil,     # required
      :keyword_id => nil, # optional, to preset the form with this keyword
      :ref_id => nil,     # options, to preset the form with this keyword
      :html_selector => nil, # Optional, specifies what should 'highlight' on success
      :link_text => 'Tag' # if you want to use other text than "Tag" for the tag link
    }.merge!(options)

    return content_tag(:em, opt[:link_text]) if opt[:object].nil?

    url = url_for(:action => :new,
                  :controller => :tag,
                  :html_selector => opt[:html_selector],
                  :tag_obj_class => opt[:object].class.to_s,
                  :tag_obj_id => opt[:object].id,
                  :keyword_id => opt[:keyword_id],
                  :ref_id => opt[:ref_id])

    # note the link has an ID that we can flash or higlight after the form it pops up successfully creates a new tag
    content_tag(:a, opt[:link_text], :href => url, 'data-basic-modal' => '' ,
                    'data-basic-modal-width' => '300', :style => 'display:inline;')
  end

  def link_to_tagged(tag)
    return "<strong style='color:red'>ERROR? #{tag.addressable_type}:#{tag.addressable_id}</strong>".html_safe if !tag.tagged_obj
    link_to(tag.tagged_obj.display_name, :action => :show, :id => tag.addressable_id, :controller => tag.addressable_type.underscore)
  end

  def link_to_referenced_object(tag)
    return "" if tag.referenced_object_object.blank?
    case tag.referenced_object_object.class.to_s
    when "String"
      return tag.referenced_object
    when "Part" # redirect to Ontology controller
      link_to(tag.referenced_object_object.display_name, :action => :show_term, :id => tag.referenced_object_object.id, :controller => :ontology)
    else
      link_to(tag.referenced_object_object.display_name, :action => :show_term, :id => tag.referenced_object_object.id, :controller => tag.referenced_object_object.class.to_s)
    end
  end

  def destroy_tag_link(o)
    url = url_for({:action => 'destroy', :controller => 'tag', :id => o.id})
    html = <<-HTML
      <form class="delete-link" method="POST" action="#{url}">
        <input name="#{request_forgery_protection_token}" type="hidden" value="#{form_authenticity_token}"/>
        <input data-ajaxify='submit' type="submit" name="delete_link" value="x" data-ajaxify-confirm="Are you sure you want to delete this tag?"> </input>
      </form>
    HTML
    html.html_safe
  end


  def render_tag_list(o)
    s = '<ul>'
    g = o.tags.group_by {|keyword| keyword.keyword}
    g.each  do |keyword, tags|
      s << "<h4>#{keyword.keyword}</h4><ul style=\"list-style-type: disc;\">"
      tags.each do |tag|
        if tag.ref
          s << '<li>' + tag.ref.display_name
        else
          s << '<li>no ref</i>'
        end
        s << " " +  destroy_tag_link(tag)
      end
      s << "</ul>"
    end
    s.html_safe
  end

  # needs some tweaking see above
  def render_list_tags(o)
    s = "<h4>Object's tags</h4>"
    # HACKISH
    if o.class.to_s == 'TaxonName'
      s << link_to('click to refresh list', :action => 'show_tags', :controller => o.class.to_s, :id => o)
    else
      s << link_to('click to refresh list', :action => 'show', :controller => o.class.to_s, :id => o)
    end

    g = o.tags.group_by {|keyword| keyword.keyword}

    g.each do |keyword, tags|
      if keyword # remove ultimately (model is properly set now)
        s << "<h4>#{keyword.keyword}</h4><ul style=\"list-style-type: disc;\">" if keyword
      else
        s << '<span style="font-weight: bolder; color: red;">ILLEGALY ORPHANED RECORD, contact your adminstrator.</span>'
      end
      tags.each do |tag|
        if tag.ref
          s << '<li>' + tag.ref.display_name
        else
          s << '<li>no ref</i>'
        end
        s << " " +  destroy_tag_link(tag)
      end
      s << "</ul>"
    end

    s.html_safe
  end

  def tag_cloud_for(o, keyword_id = 'mx_all_kw', link_back = 'list')
    if keyword_id == 'mx_all_kw'
      words= Keyword.find(:all, :include => :tags, :group => 'keyword_id, tags.addressable_type, tags.addressable_id', :order => 'keywords.keyword ASC', :conditions => ["(tags.addressable_id = ? and tags.addressable_type = ?)",  o.id, o.class.to_s])
    else
      words= Keyword.find(:all, :include => :tags, :group => 'keyword_id, tags.addressable_type, tags.addressable_id', :order => 'keywords.keyword', :conditions => ["(tags.addressable_id = ? and tags.addressable_type = ? and keywords.id = ?)",  o.id, o.class.to_s, keyword_id])
    end

    p = 10 # minimum font size, max is n * (n/2), and occurs when > 100 tags are on an object (need to set once in ENV likely, see also method below)
    s = ''
    words.each do |w|

      s << "<div id=\"cld_wrd_id_#{w.id}_#{o.class.to_s}_#{o.id}\""  # cld_wrd_id_12
      s << ' style="display: inline; padding: 0 .2em; margin-left: .1em; font-size:'

      # assumes you have at least 1 tag
      c = Tag.find(:all, :conditions => ["(tags.addressable_id = ? and tags.addressable_type = ? and keyword_id = ?)",  o.id, o.class.to_s, w.id]).size.to_i # tags.count.to_i

      case c
        when 1
          s << p.to_s # percent
        when 2..100
          s << ( p + ( p * (c.to_f / 100)).to_i ).to_s # hmm- this is likely not right, but it appears to work
        else
          s << (p + p).to_i.to_s
      end

      s << "px; background-color: ##{w.html_color};\">"

      case link_back
        when 'list'
          s << link_to(w.keyword, :action => :show_tags, :controller => :keyword, :id => w.id)
        when 'info'
          s << link_to(w.keyword, :remote => true, :url => {:action => :_popup_info, :controller => :tag, :addressable_id => o.id, :addressable_type => o.class.to_s, :keyword_id => w.id})
        else
          s << w.keyword
      end

      s << '<br style="clear:both; display:none; /"></div> '

    end
    s = "<i id=\"blue_sky_#{o.class.to_s}_#{o.id}\">blue sky</i>" if words.size == 0
    s.html_safe
  end

  def render_meta_tree(t, s = '', level = 0)
    s << render(:partial => 'tag/tn', :object => t, :locals => {:level => level, :newly_inserted => false})
    t.metatags.each do |mt|
      level += 1
      render_meta_tree(mt, s, level )
    end
    s.html_safe
  end

  def render_meta_tree_for_public(t, s = '', level = 0)
    s << render(:partial => '/public/tag/tn', :object => t, :locals => {:level => level, :newly_inserted => false})
    t.metatags.each do |mt|
      level += 1
      render_meta_tree_for_public(mt, s, level )
    end
    s.html_safe
  end

end
