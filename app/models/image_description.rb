class ImageDescription < ActiveRecord::Base
  has_standard_fields

  include ModelExtensions::DefaultNamedScopes

  belongs_to :image  # We don't require a image because ImageDescripion is mocked to be used for requests/to do lists as well
  belongs_to :image_view
  belongs_to :otu
  belongs_to :label
  belongs_to :specimen

  validates_presence_of :image

  validate :check_record
  def check_record
    errors.add(:otu_id, "Either an OTU or a specimen is required for this image description.") if otu.blank? && specimen.blank?
    errors.add(:otu_id, "Choose only one of OTU or specimen, not both for an image description.") if !otu.blank? && !specimen.blank?
    errors.add(:label_id, "Choose either a label or ontology class or neither, not both.") if !label.blank? && !ontology_class_xref.blank?
  end

  scope :with_ontology_class_xref, lambda {|*args| {:conditions => ["ontology_class_xref = ?", args.first ? args.first : -1]}}
  scope :with_image_view_id, lambda {|*args| {:conditions => ["image_view_id = ?", args.first ? args.first : -1]}}
  scope :with_stage, lambda {|*args| {:conditions => ["stage = ?", args.first ? args.first : -1]}}
  scope :with_sex, lambda {|*args| {:conditions => ["sex = ?", args.first ? args.first : -1]}}
  scope :with_proj_id, lambda {|*args| {:conditions => ["proj_id = ?", args.first ? args.first : -1]}}
  scope :with_otu_id, lambda {|*args| {:conditions => ["otu_id = ?", args.first ? args.first : -1]}}
  scope :with_specimen_id, lambda {|*args| {:conditions => ["specimen_id = ?", args.first ? args.first : -1]}}
  # :scope :is_public, :conditions => 'is_public is true'

  def display_name(options = {}) # :yields: String
    opt = {:type => :inline
    }.merge!(options.symbolize_keys)

    s = ''

    case opt[:type]
    when :for_select_list
      s =  '<div style="border: 1px solid silver; padding: 1px; margin: 1px; width: 100%; font-size: smaller;">'
      s << '<img src="' + self.image.path_for(:size => :thumb) + '" width=80 align=center style="padding-left: 2px;" />'
      s <<  "&nbsp; #{self.image_id.to_s}<br />#{otu ? otu.display_name : specimen.display_name }"
      s << " / " + self.label.display_name if self.label
      s << " / " + self.image_view.display_name if self.image_view && self.label
      s << '</div>'
    when :label_view
      s << label.display_name if label
      s << " / " + image_view.display_name if image_view
    else
      d = []
      d << otu.display_name if otu
      d << label.display_name if label
      d << image_view.display_name if image_view && label
      d << '<img src="' + image.path_for(:size => :thumb) + '"  width=40 />'
      s = d.join(" / ")
    end
    s
  end

  def ontology_class # :yields: mx OntologyClass | nil
    return nil if ontology_class_xref.blank?
    OntologyClass.find(:first, :conditions => {:proj_id => Proj.find(proj_id).ontology_id_to_use, :xref => ontology_class_xref})
  end

  def self.add_from_project(params = {})
    begin
      ImageDescription.transaction do
        @otu =   Otu.find(params[:otu]["id_#{params[:image_description_id]}"])
        @label = params[:label]["id_#{params[:image_description_id]}"].blank? ? nil : Label.find(params[:label]["id_#{params[:image_description_id]}"])
        @new_id = ImageDescription.new(
          :otu => @otu,
          :label => @label,
          :image_id => params[:image_id],
          :image_view_id => params[:image_description][:image_view_id],
          :proj_id => params[:proj_id]
        )
        @new_id.save!
      end

    rescue ActiveRecord::RecordInvalid => e
      return false # flash[:notice] = e.message
    end
    @new_id
  end

  def self.random_set(proj_id, num = 1, public = true)
    id = ImageDescription.find(:all, :conditions => ["proj_id = ? and is_public = ?", proj_id, public ? 1 : 0])
    ids = []
    id.size < num and num = id.size
    for i in (1..num)
      ids << id[rand(id.size)]
    end
    ids
  end

  def self.find_for_auto_complete(params)
    terms = []
    if params[:image_description]
      terms.push("(otu_id = #{params[:image_description][:otu_id]})") unless params[:image_description][:otu_id].blank?
      terms.push("(label_id = #{params[:image_description][:label_id]})") unless params[:image_description][:label_id].blank?
      terms.push("(image_view_id = #{params[:image_description][:image_view_id]})") unless params[:image_description][:image_view_id].blank?
      terms.push("(specimen_id = #{params[:image_description][:specimen_id]})") unless params[:image_description][:specimen_id].blank?
      terms.push("(image_id = #{params[:image_description][:image_id]})") unless params[:image_description][:image_id].blank?
    end

    return [] if terms.size == 0

    sqltxt = ''
    sqltxt = terms.join(' AND ')

    ImageDescription.find(:all,
      :include => [:image, {:otu => {:taxon_name => :parent}}, :label, :image_view, :specimen], :order => "image_descriptions.image_id",
      :conditions => "(image_descriptions.proj_id = #{params[:proj_id]})" + (sqltxt.size > 0 ? " AND (#{sqltxt})" : ''))
  end

end
