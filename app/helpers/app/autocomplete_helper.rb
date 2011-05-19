# encoding: utf-8
module App::AutocompleteHelper
  ### auto_complete formatting (h is turned off in mx) 

  # AJAX, for use in all search dropdowns
  def auto_complete_result_with_ids2(options = {}) # :yields: String
    opt = {
      :entries => nil,
      :format_method => nil,
      :id_str => nil,
      :search_text => nil
    }.merge!(options)

    return unless opt[:entries]

    items = opt[:entries].map { |entry| content_tag("li", self.send(opt[:format_method], :search_text => opt[:search_text], :entry => entry), "id" => "#{opt[:id_str]}::#{entry.id}") }
    items << content_tag("li", "-- none --", "id" => "#{opt[:id_str]}::::")
    content_tag("ul", items)
  end

  def format_ontology_class_for_auto_complete(options = {})
    pl = options[:entry].preferred_label  
    str = ''
    definition = " " + content_tag(:span, options[:entry].definition, :style => 'font-family:"Times New Roman",Georgia,Serif;')
    if options[:search_text] == pl.name # search text is an exact match
      str = content_tag(:strong, pl.name, :style => 'color:green;') + " " + content_tag(:span, '(preferred label)', :class => 'small_grey') + definition

    elsif options[:search_text] == options[:entry].id.to_s  # search is an mx id match
      str = content_tag(:strong, options[:search_text], :style => 'color:green;') + content_tag(:span, " (matches mx ID for '#{pl.name})' ", :class => 'small_grey') + definition
    elsif options[:search_text] == options[:entry].xref # search is a xref match
      str = content_tag(:strong, options[:search_text], :style => 'color:green;') + content_tag(:span, " (matches URI ID for '#{pl.name})' ", :class => 'small_grey') + definition
    else

      lbls = options[:entry].labels.collect{|l| (l.name =~ /#{options[:search_text]}/i) ? l : nil}.compact

      if lbls.size == 0 # search text found in a definition
        str = content_tag(:span, "(in defintion for '#{options[:entry].preferred_label.name}')", :class => 'small_grey') + " " +
          content_tag(:span, options[:entry].definition.gsub(/(#{options[:search_text]})/i, content_tag(:strong, "\\1", :style => 'color:green;')  ), :style => 'font-family:"Times New Roman",Georgia,Serif;'    )
      else # search text is a synonym or partial match

        exact_matches = lbls.collect{|m| m.name == options[:search_text] ? m : nil}.compact
        if exact_matches.size > 0 # search text is a exact synonym match
          str += exact_matches.collect{|m|m.name.gsub(/#{options[:search_text]}/i, content_tag(:strong, options[:search_text], :style => 'color:green;') )}.join("; ") +  " " + content_tag(:span, "(synonym for '#{options[:entry].preferred_label.name}')", :class => 'small_grey')  + definition
        else
          if lbls.size == 1
            str =  lbls[0].name.gsub(/#{options[:search_text]}/i, content_tag(:strong, options[:search_text], :style => 'color:green;') )
            if lbls[0] == pl # search text is a partial match
              str += " " + content_tag(:span, "(partial match)", :class => 'small_grey') 
            else # search text is a partial match of a synonymous label
              str += " " + content_tag(:span, "(partial match of synonym for '#{options[:entry].preferred_label.name}')", :class => 'small_grey') 
            end
          else # multiple matches, most likely synonymous
            str = lbls.collect{|l| l.name.gsub(/#{options[:search_text]}/i, content_tag(:strong, options[:search_text], :style => 'color:green;') ) }.compact.join("; ") + 
            " " + content_tag(:span, "(multiple partial matches)", :class => 'small_grey') + " " + definition 
          end
          str += " " + definition 
        end      
      end
    end
    content_tag(:div, str, :style=> 'border-bottom: 1px dotted silver;padding:0.3em;font-size:larger; text-align:left;') 
  end

  # AJAX, for use in all search dropdowns
  def auto_complete_result_with_ids(entries, format_method, id_str) # :yields: String
    return unless entries
    items = entries.map { |entry| content_tag("li", self.send(format_method, entry), "id" => "#{id_str}::#{entry.id}") }
    items << content_tag("li", "-- none --", "id" => "#{id_str}::::")
    content_tag("ul", items).html_safe
  end

  # AJAX, for use in all search dropdowns
  def auto_complete_result_with_ids_and_class(entries, format_method, id_str) # :yields: String
    return unless entries
    items = entries.map { |entry| content_tag("li", self.send(format_method, entry), "id" => "#{entry.class.name}::#{entry.id}") }
    items << content_tag("li", "-- none --", "id" => "#{id_str}::::")
    content_tag("ul", items)
  end

  def format_ontology_result_for_auto_complete(o) # :yields: String
    case o.class.name
    when "Label"
      content_tag('div', o.name, :class => 'ont_label', :style => 'padding: 2px;')
    when "OntologyClass"
      content_tag('div', o.definition, :class => 'ont_class', :style => 'padding: 2px;')
    when "Tag"
      content_tag('div', o.display_name, :class => 'ont_tag', :style => 'padding: 2px;')
    else
      content_tag('em', 'error', :class => 'failed')
    end 
  end

  # if you just use display_name in the picker you can use this method in the controller...erm this should not be needed?!
  def format_obj_for_auto_complete(o) # :yields: String 
    o.display_name(:type => :for_select_list)
  end

  # TODO: deprecate all these for Obj#display_name(:type => :for_select_list)
  # DEPRECATE
  def format_image_description_for_autocomplete(o)
    o.display_name(:type => :ajax_dropdown)
  end
  
  # DEPRECATE
  def format_geog_for_auto_complete(geog)
    n = geog.name
    if geog.geog_type
      n << content_tag("span", " [#{geog.geog_type.name}]", :style => 'color:#888;')
      n << " #{geog.state.name}" if (geog.state and (geog.geog_type.name != 'state'))  
      n << " #{geog.country.name}" if (geog.country and geog.geog_type.name != 'country') 
    else
      n << 'foo'
    end
    n  
  end

  # DEPRECATE
  def format_repository_for_auto_complete(rep)
    truncate(rep.display_name, 90)
  end

  # DEPRECATE  
  def format_serial_for_auto_complete(serial)
    "#{serial.name}  <span class=\"small_grey\">(id: #{serial.id})</span>"
  end

  # DEPRECATE?
  def format_taxon_name_for_auto_complete(tn)
    if tn.valid_name_id.blank? 
      tn.display_name(:type => :for_select_list) + " " + content_tag("span", tn.parent_name, :style => 'color: #888')
    else
      "<span style=\"color:red;\">#{tn.display_name(:type => :for_select_list)} ( =" + content_tag("span", tn.valid_name.display_name(:type => :for_select_list) + " " + content_tag("span", tn.valid_name.parent.display_name(:type => :for_select_list)), "style" => 'color: #888')  + ')</span>'
    end
  end
  
end
