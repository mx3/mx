module AccountHelper
  def render_errors(obj)
    return "" unless obj
    return "" unless request.post?
    
    unless obj.valid?
      content_tag :ul, :class => 'objerrors' do
        obj.errors.to_a.each{|attr,msg| content_tag(:li, "#{attr} - #{msg}") }
      end
    else
      String.new
    end
  end
end
