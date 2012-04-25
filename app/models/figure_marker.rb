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

  protected

  def strip_unused_attributes_from_svg
    begin
      # do some cleanup on the incoming string
      txt = self.svg
      txt.strip!
      txt.gsub!(/\n+\s*/, "\s") # compress whitespace
      txt.gsub!(/\n/, '')       # compress whitespace
      txt.gsub!(/\t/, '')       # strip tabs

      # self.logger.info "incoming figure marker text: #{txt}" + txt

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
          # if Application::ALLOWED_SVG_ATTRIBUTES.include?(k) # see environment.rb
          #  e.delete_attribute(k)
          #  next
          # end
          # and this is likely necessary either
          e.attribute(k).value.gsub!(/\n+\s*/, "\s") # compress somewhitespace
        end
      end

    rescue REXML::ParseException => e
      return false
    end

     # self.logger.info "parsed: #{s}"
     # self.logger.info "parsed.to_s: #{s.to_s}"

    # have to loop the elements here and check each one individually
    #  return false if !s.elements.first.has_attributes?
    self.svg = s.to_s
  end

end
