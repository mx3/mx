# encoding: utf-8
module GeogHelper

 def indented_geog_tag(geog, content)  
    "<div class=\"#{geog.geog_type.name}\">
        <div><span class=\"#{geog.geog_type.name}\">#{geog.name}</span> <span style='font-size: smaller;'>(#{content})</span></div>
    </div>"
 end

end
