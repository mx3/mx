# encoding: utf-8
module ImageHelper

  # Resizes MB and mx images to a "standard" thumb size
  # this does not render SVG overlays
  def image_thumb_tag(image)
    # note that path_for(:size => :thumb) actually returns a link to the medium size for MB
    return ('<img src="' + image.path_for(:size => :thumb) + '" alt="' + image.id.to_s + '_mbimage" height="160" />' ) if image.is_morphbank
    # SEE image_tag deprecation in 2.0 (appends .png till 2.0)
    image_tag(image.path_for(:size => :thumb), image.thumb_scaler) # .gsub(/\.png/, '')
  end

  def figure_image_stroke_width(img, figure, size = :medium)
    return 0 if img.nil?

    stroke = case figure.marker_type
      when 'area'
        case size
        when :thumb
        0 # might be zero
        else
        1
        end
      else
        a = [img.height, img.width].max
        case size
        when :thumb
          case a
          when 0..100
            5
          when 101..1000
            5
          else # what is this case?
            60
          end
        when :medium
          case a
          when 0..100
            10
          when 101..1000
            20
          else
            30
          end
        when :big
          case a
          when 0..100
            20
          when 101..1000
            30
          else
            40
          end
        when :original
          case a
          when 0..100
            30
          when 101..1000
            40
          else
            50
          end
        else
          0
        end
      end

  end

  def image_with_svg_tag(image, options = {}) # :yields: String
    options = {:size => :medium,
               :link => '',
               :figure_markers => [],
               :image => image
              }.merge(options)
    render :partial => "shared/svg_image", :locals=> options
  end
end
