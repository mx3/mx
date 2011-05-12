# encoding: utf-8
module ImageHelper

  # Resizes MB and mx images to a "standard" thumb size
  # this does not render SVG overlays
  def image_thumb_tag(image)
    # note that path_for(:size => :thumb) actually returns a link to the medium size for MB
    return ('<img src="' + image.path_for(:size => :thumb) + '" alt="' + image.id.to_s + '_mbimage" height="160" />' ) if image.is_morphbank 
    image_tag(image.path_for(:size => :thumb), image.thumb_scaler) # .gsub(/\.png/, '') # SEE image_tag deprecation in 2.0 (appends .png till 2.0)
  end

  # TODO: Deprecate for optioned version below
  def image_with_svg_tag(image) # :yields: String 
    content_tag(:div, :id => "image_#{image.id}_img", :class => 'image') do 
      if image.figure_markers.size > 0
        update_page_tag do |page|
          page.call 'createSvgObjRoot', (request.xml_http_request? ? 'ajax' : 'http'), *image.svgObjRoot_params(:size => :medium, :link => '' )
        end
      end
    end 
  end

  def image_with_svg_markers_tag(options = {}) # :yields: String 
    opt = {
      :image => nil,
      :figure_markers => [] 
    }.merge!(options)

    content_tag(:div, :id => "image_#{opt[:image].id}_img", :class => 'image') do 
      if opt[:figure_markers].size > 0
        update_page_tag do |page|
          page.call 'createSvgObjRoot', (request.xml_http_request? ? 'ajax' : 'http'), *opt[:image].svgObjRoot_params(:size => :medium, :link => '' )
        end
      end
    end 
  end

  # TODO: need an image with figure markers version

  def svg_test(options = {})
    opt = {
      :image => nil,
      :target => "", 
      :scale => nil,
      :size => :medium,                  # :thumb, :medium, :big, :original
      :link_target => '_blank',
      :link => nil # 'http://127.0.0.1:3000/'
    }.merge!(options.symbolize_keys)

    img = opt[:image]

     xml = Builder::XmlMarkup.new(:indent=> 2, :target => opt[:target])

     xml.svg(:id => "fig_svg_#{self.id}",
             :width => img.width_for_size(opt[:size]).round.to_i,
             :height => img.height_for_size(opt[:size]).round.to_i,
             :display => 'inline', # was block
             :xmlns => 'http://www.w3.org/2000/svg',
             'xmlns:xlink' => "http://www.w3.org/1999/xlink"
            ) {

       xml.a('xlink:href' => opt[:link], :target => opt[:link_target])  {
         xml.image( :x => 0,  
                    :y => 0,
                   'width' => img.width_for_size(opt[:size]).round.to_i,
                   'height' => img.height_for_size(opt[:size]).round.to_i,  
                   'id' => 'someid',
                   'xlink:href' => img.xlink_href(opt[:size]) 
          )

          xml.g(:id => "markers_for_fig_#{self.id}", :transform => "scale(#{img.width_scale_for_size(opt[:size])})") {  # to 6 decimal places     
            img.figure_markers.ordered_by_position.each do |fm|
              xml << fm.render('stroke-width' => fm.stroke_width_for_image_and_size(img, opt[:size])) 
            end
          }
        }
     }
 

    opt[:target] 
  end

end
