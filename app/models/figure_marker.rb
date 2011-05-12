class FigureMarker < ActiveRecord::Base
  has_standard_fields

  include ModelExtensions::DefaultNamedScopes

  belongs_to :figure
  has_one :image, :through => :figure

  acts_as_list :scope => :figure # first is topmost

  validates_presence_of [:svg, :figure]

  ALLOWED_BASE_ATTRIBUTES = []
  FIGURE_MARKER_TYPES = [:point, :line, :area, :volume]
  DEFAULT_OPACITY = 0.4

  after_create :energize_create_figure_marker

 def energize_create_figure_marker
   if figure.addressable_type == "OntologyClass"
     figure.figured_obj.labels.each do |l|
       l.energize(creator_id, 'added a SVG annotation to a class labeled with')
       l.save!
     end 
   end
   true
 end

  after_destroy :energize_destroy_figure_marker

  def energize_destroy_figure_marker
    if figure.addressable_type == "OntologyClass"
      figure.figured_obj.labels.each do |l| 
        l.energize(creator_id, "destroyed a SVG annotation on a class labeled with")
        l.save!
      end 
    end
    true
  end

  before_save :strip_unused_attributes_from_svg

  # return a valid svg element including stroke and fill
  def render(options = {})
    opt = {
      :id => "marker_#{self.id}",
      :stroke => '#14eddd',
      :fill => '#14eddd',
      :opacity => DEFAULT_OPACITY, 
      :display => 'inline',
      'stroke-width' => 2
    }.merge!(options)

    target = ''

    xml = Builder::XmlMarkup.new(:indent=> 2, :target => target)
    if opt['xlink:href']
    xml.a('xlink:href' => opt['xlink:href'], :target => '_parent') {
        opt.delete('xlink:href')
        opt.delete('link_target')
        xml.g(opt) {
        xml << self.svg
      }
    }

    else 
    xml.g(opt) {
      xml << self.svg
    }
    end
    
    target 
  end

  def stroke_width_for_image_and_size(img, size = :medium)

    return false if img.nil?

    case marker_type
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

  protected

  def strip_unused_attributes_from_svg
    begin
      # do some cleanup on the incoming string
      txt = self.svg
      txt.strip!
      txt.gsub!(/\n+\s*/, "\s") # compress whitespace
      txt.gsub!(/\n/, '')       # compress whitespace
      txt.gsub!(/\t/, '')       # strip tabs

      self.logger.info "incoming figure marker text: #{txt}" + txt

      s = REXML::Document.new(txt)

      return false if s.elements.size == 0  # FIX THIS
      REXML::XPath.match(s, "//").each do |e|
        # strip the unecessary Text nodes that might have been picked up
        if e.class == REXML::Text
          e.parent.delete(e) 
          next
        end 
        e.attributes.keys.each do |k|
          # we likely don't need this, it's cleaned in sanitize!
          if !ALLOWED_SVG_ATTRIBUTES.include?(k) # see environment.rb
            e.delete_attribute(k) 
            next
          end
          # and this is likely necessary either
          e.attribute(k).value.gsub!(/\n+\s*/, "\s") # compress somewhitespace
        end
      end

    rescue REXML::ParseException => e
      return false
    end

     self.logger.info "parsed: #{s}"
     self.logger.info "parsed.to_s: #{s.to_s}"

    # have to loop the elements here and check each one individually
    #  return false if !s.elements.first.has_attributes?
    self.svg = s.to_s
  end

end
