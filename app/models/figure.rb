# == Schema Information
# Schema version: 20090930163041
#
# Table name: figures
#
#  id                      :integer(4)      not null, primary key
#  addressable_id          :integer(4)
#  addressable_type        :string(64)
#  image_id                :integer(4)      not null
#  position                :integer(1)
#  caption                 :text
#  updated_on              :timestamp       not null
#  created_on              :timestamp       not null
#  creator_id              :integer(4)      not null
#  updator_id              :integer(4)      not null
#  proj_id                 :integer(4)      not null
#  morphbank_annotation_id :integer(4)      TODO: DEPRECATED
#  svg_txt                 :text            DEPRECATED!
#

class Figure < ActiveRecord::Base
  has_standard_fields

  include ModelExtensions::DefaultNamedScopes

  belongs_to :addressable, :polymorphic => true
  belongs_to :image
  has_many :figure_markers, :dependent => :destroy

  acts_as_list :scope => 'addressable_id = #{addressable_id} AND addressable_type = \"#{addressable_type}\"'

  scope :with_figure_markers, :conditions => 'id IN (SELECT figure_id FROM figure_markers)'
  scope :without_figure_markers, :conditions => 'id NOT IN (SELECT figure_id FROM figure_markers)'
  scope :not_using_morphbank_images,  :include => [:image], :conditions => 'images.mb_id is null'
  scope :with_licensed_images,  :include => [:image], :conditions => 'length(images.license) > 0'

  validates_presence_of :image_id
  validates_presence_of :addressable_id
  validates_presence_of :addressable_type

  after_update :save_figure_markers

  after_create :energize_add_figure
 after_destroy :energize_add_figure

  def energize_add_figure(person_id = $person_id)
    if addressable_type == "OntologyClass"
      figured_obj.labels.each do |l|
        l.energize(person_id, "destroyed a figure on a class labeled with")
        l.save!
      end
    end
    true
  end

  # Not presently implemented in the app
  def figure_marker_attributes=(figure_marker_attributes)
    figure_marker_attributes.each do |attributes|
      next if attributes == {}
      if attributes[:id].blank?
        figure_markers.build(attributes)
      else
        a = figure_markers.detect { |t| t.id == attributes[:id].to_i }
        a.attributes = attributes
      end
    end
    true
  end

  def save_figure_markers
    figure_markers.each do |a|
      a.save(:validate => true) # passing false ignores validation -- ugh!
    end
    true
  end

  def display_name(options = {})
    opt = {:type => :inline
    }.merge!(options.symbolize_keys)
    case opt[:type]
    when :on
      figured_obj ?
      figured_obj.display_name(:type => :figure) :
      "<strong style='color:red;'> ORPHANED #{addressable_type}: #{addressable_id} </strong>"
    else
      # ?!
    end
  end

  def self.create_new(new_figure_params = {}) # :yields Figure
    opt = {
      :obj => nil,   # also include the@obj to figure
      :addressable_id => new_figure_params[:obj].id,
      :addressable_type => new_figure_params[:obj].class.to_s
    }.merge!(new_figure_params).to_options!
    opt.delete(:obj)
    t = Figure.new(opt)
    t.save
    t
  end

  def figured_obj # :yields: Object the figure is attached to
    begin
      ActiveRecord::const_get(self.addressable_type).find(self.addressable_id)
    rescue
      return false
    end
  end

  def text_width_chrs(font_size = 5.5) # :yields: Float - the number of characters for a pixel width of w, font_size of 8(units?)
    self.image.width_for_size(:thumb).to_f / font_size
  end

  def self.create_all_for_content_by_otu(content_id, otu_id) # :yields: True | False - Adds all possible images as figures for the otu/content combination
    ## TODO should be abstracted to allow attachment to any object type
    @o = Otu.find(otu_id) or return false
    @c = Content.find(content_id) or return false
    begin
      Figure.transaction do
        @o.images.each do |i|
          if !Figure.find(:first, :conditions => {:addressable_id => @c.id, :addressable_type => @c.class.to_s, :image_id => i.id})
            f = Figure.new(:addressable_id => @c.id, :addressable_type => @c.class.to_s, :image_id => i.id)
            f.save!
          end
        end
      end
    rescue
      return false
    end
    true
  end
end
