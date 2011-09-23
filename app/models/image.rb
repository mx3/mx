# == Schema Information
# Schema version: 20090930163041
#
# Table name: images
#
#  id               :integer(4)      not null, primary key
#  file_name        :string(64)
#  file_md5         :string(32)
#  file_type        :string(4)
#  file_size        :integer(4)
#  width            :integer(3)
#  height           :integer(3)
#  user_file_name   :string(64)
#  taken_on_year    :integer(2)
#  taken_on_month   :integer(1)
#  taken_on_day     :integer(1)
#  owner            :string(255)
#  ref_id           :integer(4)
#  technique        :string(12)
#  mb_id            :integer(4)
#  notes            :text
#  updated_on       :timestamp       not null
#  created_on       :timestamp       not null
#  creator_id       :integer(4)      not null
#  updator_id       :integer(4)      not null
#  proj_id          :integer(4)      not null
#  copyright_holder :string(255)
#  contributor      :string(255)
#

require 'digest/md5'

class Image < ActiveRecord::Base
 
  # if you add validation here, make sure to check that its applicable (or not) in MorphBank image controller

  include ImageManipulation
  include ModelExtensions::DefaultNamedScopes
  include ModelExtensions::MiscMethods

  has_standard_fields 

  # protected from mass-assignment  
  attr_protected :file_name, :file_type, :file_size, :user_file_name # :file_md5, 
 
  MIN_YEAR = 1700 # oldest allowed 'taken_on' date
  TECHNIQUES = ["brightfield", "SEM", "illustration", "brightfield (stereo/Automontage)", "brightfield (compound/combineZ)", "brightfield (stereo/combineZ)", "CLSM (Confocal Laser Scanning Microscopy)"]

  belongs_to :ref

  has_many :figures, :dependent => :destroy  
  has_many :figure_markers, :through => :figures
  has_many :image_descriptions, :dependent => :destroy
  has_many :otus, :through => :image_descriptions 
  has_many :images, :through => :image_descriptions 

  validates_inclusion_of :taken_on_year, :in => MIN_YEAR..Date.today.year, :message => "must be between #{MIN_YEAR} and #{Date.today.year}", :allow_nil => true
  validates_inclusion_of :taken_on_month, :in => 1..12, :message => "must be between January (1) and December (12)", :allow_nil => true

  scope :without_image_descriptions, :include => [:image_descriptions], :conditions => 'image_descriptions.id IS NULL'

  before_update :validate_license

  def validate_license
     if !CONTENT_LICENSES.keys.include?(license)
        errors.add(:license, ' image must have a valid license, if you want another option added contact an admin')
     end
  end 

  scope :from_morphbank, :conditions => 'mb_id is not null and mb_id != ""'
  scope :with_figure_markers, :conditions => "figure_markers.figure_id is not null", :include => [:figures, :figure_markers]
  scope :after_id, lambda  {|*args| {:conditions => ["images.id > ?", args.first.blank? ? nil : args.first] }}
  scope :before_id, lambda {|*args| {:conditions => ["images.id < ?", args.first.blank? ? nil : args.first] }}

  def display_name(options = {})
   return "Image #{self.id}"
  end
  
  # crude, but as implemented in image descriptions it works
  def is_morphbank
    mb_id?
  end

  # Returns the true, unscaled height/width ratio
  def hw_ratio # :yields: Float
    raise if height.nil? || width.nil? # if they are something has gone badly wrong 
    return (height.to_f / width.to_f)
  end
 
  def taken_on # :yields: String
    [taken_on_day, taken_on_month, taken_on_year].compact.join("/")
  end  

  # used in ImageHelper#image_thumb_tag
  # asthetic scaling of very narrow images in thumbnails
  def thumb_scaler # :yields: Hash
    a = self.hw_ratio
    if a < 0.6
      { 'width' => 200, 'height' => 200 * a}
    else
      {}
    end
  end

  # the scale factor is typically the same except in a few cases where we skew small thumbs
  def width_scale_for_size(size = :medium) # :yields: Float
    (width_for_size(size).to_f / width.to_f) 
  end

  def height_scale_for_size(size = :medium) # :yields: Float
    height_for_size(size).to_f / height.to_f
  end

  def width_for_size(size = :medium) # :yields: Float
    a = self.hw_ratio 
    case size
    when :thumb
      a < 0.6 ? 200.0 : ((width.to_f / height.to_f ) * 160.0)
    when :medium
      a < 1 ? 640.0 : 640.0 / a  
    when :big
      a < 1 ? 1600.0 : 1600.0 / a  
    when :original
      width 
    else
      nil
    end
  end

  def height_for_size(size = :medium) # :yields: Float
    a = self.hw_ratio 
    case size
    when :thumb
      a < 0.6 ? 213.0 * height.to_f / width.to_f : 160
    when :medium
      a < 1 ? a * 640 : 640
    when :big
      a < 1 ? a * 1600 : 1600
    when :original
      height
    else
      nil 
    end
  end

  #**********************
  # IMAGE FILE HANDLING #
  #######################

  before_validation :record_image_details
  after_save :store_and_derive_files
  before_destroy :delete_all_files
    
  # checks for errors that the user has no control over, such as missing files and bad checksums
  def backend_validate
    # TODO: resolve as to whether we need this (haven't yet apparently) 
    # if we have the img attribute set (the file name), we should have a file
    # errors.add(:base, "Can't find image file!") if (file_name? and not File.exists?("#{IMAGE_FILE_PATH}original/#{file_name}"))
    # validates file_md5 == md5_from_real_file unless :temp_file
  end
  
  def file=(incoming_file)
    @temp_file = incoming_file if incoming_file.size > 0
  end
  
  def original_file
    "original"
  end

  def allowed_formats
    {
      "BMP" => "bmp",
      "GIF" => "gif",
      "JPEG" => "jpg",
      "PNG" => "png",
      "PSD" => "psd",
      "TIFF" => "tif"
    }
  end
  
  def derived_files
    # for speed, use different source files to create different derived files
    # :x => "" allows the x dimension to be unconstrained for thumbs
    {
      :big => {:x => 1600, :y => 1600, :source => :original},
      :medium => {:x => 640, :y => 640, :source => :big},
      :thumb => {:x => "", :y => 160, :source => :medium, :quality => 90, :sharpen => "-sharpen 2"}
    }
  end
 
  def xlink_href(size)
    s =  self.path_for(:size => size)
    self.is_morphbank ? s : ModelExtensions::MiscMethods.host_url + s
  end

  # return a URI to an image 
  def path_for(options = {})
    opt = {
      :size => :medium,               # :thumb, :medium, :original (morphbank), additional :big for mx
      :context => :web,
    }.merge!(options.symbolize_keys)

    if self.is_morphbank
       MorphbankImage::BASE_URL + '?id=' + self.mb_id.to_s + '&imgType=' + MorphbankImage::SIZE_TO_TYPE[opt[:size]]
    else 
      # original pre-morphbank code below
      path = (opt[:context] == :file ? File.expand_path(IMAGE_FILE_PATH) : IMAGE_WEB_PATH)
      # expand_path elminates trailing /
      if opt[:size] == :original
       "#{path}/original/#{file_name}.#{self.file_type}" 
      else
        "#{path}/#{opt[:size]}/#{file_name}.jpg" if derived_files[opt[:size]]
      end
    end
  end

  # renders an SVG representation of the figure
  def svg(options = {})
    opt = {
      :target => "", 
      :scale => nil,
      :size => :medium,                  # :thumb, :medium, :big, :original
      :link_target => '_blank',
      :link => nil # 'http://127.0.0.1:3000/'
    }.merge!(options.symbolize_keys)
      xml = Builder::XmlMarkup.new(:indent=> 2, :target => opt[:target])

     xml.svg(:id => "img_svg_#{self.id}",
             :width => width_for_size(opt[:size]).round.to_i,
             :height => height_for_size(opt[:size]).round.to_i,
             :display => 'inline', # was block
             :xmlns => 'http://www.w3.org/2000/svg',
             'xmlns:xlink' => "http://www.w3.org/1999/xlink"
            ) {
      
         xml.image( :x => 0,  
                    :y => 0,
                   'width' => width_for_size(opt[:size]).round.to_i,
                   'height' => height_for_size(opt[:size]).round.to_i,  
                   'id' => "image_#{self.id}",
                   'xlink:href' => xlink_href(opt[:size]) 
          )


          xml.g(:id => "markers_for_image_#{self.id}", :transform => "scale(#{width_scale_for_size(opt[:size])})") {  # to 6 decimal places     

       figure_markers.each_with_index do |fm,i  |
        xml << fm.render(
                         :opacity => '0.55',
                         :fill => "#" + ColorHelper.palette(:index => i % 11, :hex => true, :palette => :cb_qual_12)[2..7],
                         'xlink:href' =>  ModelExtensions::MiscMethods.host_url + "/projects/#{fm.proj_id}/ontology_class/show/#{fm.figure.figured_obj.id}"
                      ) 
       end  
     }  

     }


    opt[:target] 
  end


  def svgObjRoot_params(options = {})
    opt = {
      :size => :medium
    }.merge!(options)
    x = width_for_size(opt[:size]).round
    y = height_for_size(opt[:size]).round
    [
      "image_#{self.id}_img",   # parentElementId
      "img_svg_root_#{self.id}", # id
      self.svg(:width => x, :height => y, :size => opt[:size], :link => opt[:link]), # svgTag
       x,  # width
       y   # height
    ]
  end

  private

  def record_image_details
    if @temp_file
      @details = im_identify(@temp_file.path) # was local_path
      self.user_file_name = @temp_file.original_filename
      self.file_type = allowed_formats[@details[:type]]
      self.file_size = @temp_file.size
      self.width = @details[:width]
      self.height = @details[:height]
      self.file_md5 = Digest::MD5.hexdigest(@temp_file.read) # this is a pointer! so everytime we rewind/read the file the file_md5 we change its value 
    end
  end
  
  def store_and_derive_files
    if @temp_file
      calc_file_name unless self.file_name? # file name does not change once the record is created
      begin
        logger.info "Storing #{path_for(:size => :original, :context => :file)}"
        if @temp_file.instance_of?(Tempfile)
          FileUtils.copy(@temp_file.path, path_for(:size => :original, :context => :file)) # mx3 was local_path
        else
          @temp_file.rewind # we already read the file to get the MD5, so rewind 
          File.open(path_for(:size => :original, :context => :file), "wb") { |f| f.write(@temp_file.read) }    
        end
        FileUtils.chmod(0644, path_for(:size => :original, :context => :file)) # writable by owner, readable by everyone
        delete_derived_files
        create_derived_files
      rescue
        logger.info "Rescuing #store_and_derive_files"
        delete_all_files
        raise
      ensure
        @temp_file = nil # prevent memory leak??
      end
    end
  end

  ##* should add date-time checking, smart creation, 'force' option
  def create_derived_files
    logger.info "Time for #create_derived_files: " + Benchmark.measure{
      begin
        [:big, :medium, :thumb].each do |version|
          options = derived_files[version]
          im_make_jpg(path_for(:size => options[:source], :context => :file), path_for(:size => version, :context => :file), options)
          raise "Failed to create #{version} version of image file." unless File.exists?(path_for(:size => version, :context => :file))
        end
      rescue
        logger.info "Rescuing #create_derived_files"
        delete_derived_files
        raise
      end
      }.to_s
  end

  def calc_file_name
    self.file_name = "#{self.id}_mximage"
    self.class.update_all("file_name = '#{self.file_name}'", "id = #{self.id}")
  end

  def delete_derived_files
    derived_files.each_key do |version|
      delete_file(path_for(:size => version, :context => :file))
    end
  end
  
  def delete_all_files
    delete_derived_files
    delete_file(path_for(:size => :original, :context => :file))
  end
      
  def delete_file(name)
    if (File.exists?(name) and not File.directory?(name))
      logger.info "Deleting #{name}"
      File.delete(name) 
    end
  end

  validate :check_record
  def check_record
    if self.new_record?
      errors.add("file", "was not specified") unless @temp_file
    else
      if $proj_id != self.proj_id
        errors.add(:base, "Images can presently only be altered in the project that created them \
         (contact your administrator if you need this changed).") 
      end
    end
    if @temp_file
      if not allowed_formats[@details[:type]]
        errors.add("file", "must be #{allowed_formats.keys.join(', ')} (is: #{@details[:type]})")
      end
      
      @temp_file.rewind # REQUIRED! otherwise the self.file_md5 points to the end
       if self.new_record? and other = self.class.find(:first, :conditions => ["file_md5 = ?", self.file_md5])
        self.errors.add("file", "has already been stored in the database (ID #{other.id}).")
      end
    end
    
    # Date validation. see also 'validates_inclusion_of' calls above
    if taken_on_month
      errors.add("taken_on_year", "is required if you specify a month") unless taken_on_year
    end
    if taken_on_day
      errors.add("taken_on_month", "is required if you specify a day") unless taken_on_month
      if taken_on_year and taken_on_month and taken_on_day
        errors.add("taken_on_day", "is not a valid date") unless Date.valid_civil?(taken_on_year, taken_on_month, taken_on_day)
      end
    end
  end

end
