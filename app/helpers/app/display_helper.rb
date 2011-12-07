# encoding: utf-8
# Methods added to this helper will be available to all templates in the application.
module App::DisplayHelper

  # now that we sanitize data before it is stored in the db
  # this just turns off the h method
  # see also acts_as_santized
  #  ... meh, should remove h() throughout

  # TODO: need to revist, if you want to use this use the alias html_escape
  # def h(t)
  #  t
  # end

  # same as textilize, except sanitizes text first
  def htmlize(text)
    text.blank? ? "" : RedCloth.new(sanitize(text)).to_html.html_safe
  end

  def hilight_string_in_text(options = {})
    opts = {:string => '', :text => '', :class => 'passed', :word_bounds => true}.merge!(options)
    return '' if opts[:string].size == 0 || opts[:text].size == 0
    b = (opts[:word_bounds] ? '\b' : '')
    opts[:text].gsub(/#{b}#{opts[:string]}#{b}/, "<span class=\"#{opts[:class]}\" style=\"padding:2px;\">#{opts[:string]}</span>").html_safe
  end

  # TODO: revist the bold/header style
  def show_header_tag(obj)
    return "no display_name method" if !obj.respond_to?('display_name')
    content_tag('div', :style => 'display:inline;') do
      obj.display_name + "&nbsp;" + content_tag('span', "(id: #{obj.id})", :class => 'small_grey')
    end
  end

  def is_public_tag(obj)
    return "no is_public method" if !obj.respond_to?('display_name')
    obj.is_public ? content_tag('span', 'yes', :class=> 'passed') : content_tag('span', 'no', :class => 'failed')
  end

  # renders a quick view of an object
  def render_show(obj, show_links = true, side_nav = true)
    @obj = obj
    @show_links = show_links
    @side_nav = side_nav
    render(:partial => '/shared/show')
  end

  def id_box_tag(obj)
    content_tag(:div, "id: #{obj.id.to_s}", :style => 'text-align:center; padding: 2px; background-color:#ddd; color:gray;')
  end

  def display_record_ccuu(obj)
   html =  content_tag(:b, 'Created by:') + obj.c_by.to_s + '<br/>' +
      content_tag(:b, 'Updated by:') + obj.m_by.to_s + '<br/>' +
      content_tag(:b, 'Created on:')  + obj.c_on.to_s + '<br/>' +
      content_tag(:b, 'Updated on:')  + obj.m_on.to_s + '<br/>'
    html.html_safe
  end

  # maybe a Table helper?
  # renders a table row of column headers
  # if you pass a hash you pass 'name' and 'class' and /or 'style' (include ";" in your style!)
  # like {'name' => 'foo', 'style' => 'bar: 0;', 'class' => 'blorf'}
  def t_col_heads(heads)
    html =   "<tr>" + heads.collect{|c| c.class.to_s == 'Hash' ?
        ("<th " +
          (c['class'] ? (" class=\"" + c['class'] + "\"") : "") +
          (c['style'] ? (" style=\"" + c['style'] + "\"") : "") + ">" +
          c['name'] + "</th>") :
        (content_tag(:th, "#{h c}"))}.join("") + "</tr>"
    html.html_safe
  end
  # A unique HTML id for an object.
  def tags_html_id(obj)
    "tags_html_#{obj.class}_#{obj.id}".underscore.downcase.html_safe
  end

  def t_row(params)           # renders a table row, requires 'obj' as a key if inc_actions ==  true
    opt = { 'inc_actions' => true, # include show/edit/destory/tag as options
      'tr_css' => "",               # a css CLASS for the row, if and integer is passed assumes it's a stripe
      'open_tr' => true,            # true - include <tr>  (useful if you want to append or prefix unescaped data to row)
      'no_show' => false,           # don't show the 'show' action link
      'close_tr' => true,           # true - include </tr>
      'cell_data' => []}            # the cell data
    opt.merge!(params)
    r = ''

    opt["tr_css"].to_s.to_i == opt["tr_css"] && opt["tr_css"] = ( opt["tr_css"] % 2 == 0 ? 'stripe' : "")
    opt['open_tr'] && ( r << "<tr id='#{tags_html_id(opt['obj'])}' class=\"" + opt["tr_css"]  + "\">")
    r << opt["cell_data"].collect{|c| c.class == Hash ? ("<td class=\"" + c.values[0] + "\">#{h c.keys[0]}</td>") : "<td>#{h c}</td>" }.join("") ## IS THIS SECURE??
    if opt['inc_actions']
      r << self.t_cell_obj_actions(opt["obj"])
    end
    opt["close_tr"] and (r << "</tr>")
    r.html_safe
  end

  def t_cell_obj_actions(o) # return show/edit/destroy tables cells for object o
    r = ''
    klass = ActiveSupport::Inflector.underscore(o.class.to_s).pluralize
    if o.taggable
      r << "<td class='list_action'>" +
        render( :partial => "tags/tag_link", :locals => { :html_selector => "##{tags_html_id(o)}",
          :tag_obj => o, :link_text => "Tag"})+ "</td>"
    end
    r << content_tag(:td, link_to('Show', :action => 'show', :controller => klass , :id => o.id, :target =>'show'), :class => :list_action)
    r << content_tag(:td, link_to('Edit', :action => 'edit', :controller => klass, :id => o.id), :class => :list_action)
    r << content_tag(:td, link_to('Destroy', {:action => 'destroy', :controller => klass, :id => o.id}, :method => "post", :confirm => ([Ref, Otu].include?(o.class) ? "WARNING! You are about to delete EVERYTHING in this project that is directly tied to this #{o.class}.  Are you sure you want to do this?" : "Are you sure?")), :class => :list_action)
    r.html_safe
  end

  def quick_table(heads, objs, include_actions)
    t = "<table>" + t_col_heads(heads.collect {|h| h.keys.first })
    for o in objs
      t << "<tr>"
      heads.collect{|h| h.values.first}.each do |m| inc_actions
        t << "<td>#{h o.send(m)}</td>"
      end

      if include_actions
        t << t_cell_obj_actions(o)
      end
      t << "</tr>\n"
    end
    t << "</table>"
    t.html_safe
  end

  def spinner_tag(id)
    image_tag('/images/spinner.gif', :alt => 'Loading', :id => id, :style => "display: none; vertical-align:middle;"  )
  end

  def expandable_caption(text, id, truncate_length = 100)
    str = ''
    xml = Builder::XmlMarkup.new(:indent=> 2, :target => str)
    # id is any unique id for the div element
    # t is the text

    trunc = truncate_length - 6 # account for truncation marks, and arrows
    if text.size > 0
      if text.size > trunc
        xml.span('id' => "cp_#{id}_short", 'style' => 'display: inline; z-index:300;') do
          # strip all html before displaying the truncated version
          stripped = htmlize(text).gsub(/\<.+?\>/, '' )
          xml << stripped[0..trunc] + "... "
        end

        # The full string of text.
        xml.span( 'id' =>  "cp_#{id}_more", "style" => "display: inline; display: none; z-index:300;") do
          xml <<  ( htmlize(text).gsub(/\<.?p\>/, '') )
        end

        xml.a("style" => 'display:inline', "onclick" => "Element.toggle('cp_#{id}_more'); Element.toggle('#{id}_minus'); Element.toggle('#{id}_plus'); Element.toggle('cp_#{id}_short')" ) do |a|
          xml.span( 'id' => "#{id}_minus", "style" => "display:none") do
            xml <<  "&#8624;"
          end
          xml.span( 'id' => "#{id}_plus", "style" => "display:inline") do
            xml << "&#8628;"
          end
        end
      else
        xml <<  ( htmlize(text).gsub(/\<.?p\>/, '') ) # basically saying no paragraph marks allowed in caption text
      end
    end

    str.html_safe
  end

end
