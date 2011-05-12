# encoding: utf-8
module RefHelper

  def short_ref_link_tag(ref)
    return "" if !ref
    link_to(ref.authors_year, :action => :show, :controller => :ref, :id => ref.id)
  end

  def context_for_label(ref, label_name)
    return content_tag(:em, "no label to provide context for") if label_name.blank?
    context = ref.ocr_text.scan(/.{0,80}#{label_name}.{0,80}/i)
   
    str = '' 
    context.each do |c|
      str += content_tag(:div, c.gsub(/#{label_name}/i, content_tag(:strong, label_name, :class => 'passed')), :style => "padding: 4px;")
    end
    str
  end

end
