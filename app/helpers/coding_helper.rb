module CodingHelper
 def coding_tag_wrapped_in_confidence(coding)
    return coding.display_name(:type => :windowed_value) if coding.confidence_id.blank?
    "#{coding.confidence.open_background_color_span}#{coding.display_name(:type => :windowed_value)}</span>".html_safe 
  end

  def coding_tag_wrapped_in_age_heat_map(coding)
    i = 255 - (255 - (Time.now - coding.created_on).round / 86400).round
    i = 255 if i > 255 || i < 0
    # basically the same values below
    # j = 255- (Time.now - coding.updated_on).round / 86400 
    # j = 255 if j > 255 || j < 0
    "<span style=\"background-color:rgb(0,#{i},0);padding: 2px;\">#{coding.display_name(:type => :windowed_value)}</span>".html_safe
  end
 
  # TODO: move to helper 
  def coding_tag_wrapped_in_tag_heat_map(coding)
   if coding.tags.count == 1 
      "<div style=\"background-color:##{coding.tags.first.keyword.html_color}; width: 10; border: 1px solid #8b2973; font-weight: bolder; margin: 0;\">#{coding.display_name(:type => :windowed_value)}</div>".html_safe
    elsif coding.tags.count > 1
      i = 255 - (coding.tags.count * 20) 
      i = 255 if i < 0
      "<div style=\"background-color:rgb(0,#{i},#{i}); width: 10; border: 1px solid #e5993a; color: white; margin: 0;\">#{coding.display_name(:type => :windowed_value)}</div>".html_safe
    else 
      coding.display_name(:type => :windowed_value).html_safe
    end
  end

  def coding_tag_wrapped_in_creator_heat_map(coding)
    if !coding.creator.pref_creator_html_color.blank?
      i = coding.creator.pref_creator_html_color
    else
      i = (255 - (2 * coding.creator_id)).round
      i = 0 if i < 0
      i = "%x" % i
      i = "eeee#{i}".html_safe 
    end
    "<span style=\"background-color:##{i}; padding: 2px;\">#{coding.display_name(:type => :windowed_value)}</span>".html_safe
  end


end



