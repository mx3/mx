# == Schema Information
# Schema version: 20090930163041
#
# Table name: gel_images
#
#  id             :integer(4)      not null, primary key
#  name           :string(255)
#  file_name      :string(64)      not null
#  user_file_name :string(255)
#  file_md5       :string(32)      not null
#  file_type      :string(4)
#  file_size      :integer(4)
#  width          :integer(3)
#  height         :integer(3)
#  notes          :text
#  proj_id        :integer(4)      not null
#  creator_id     :integer(4)      not null
#  updator_id     :integer(4)      not null
#  updated_on     :timestamp       not null
#  created_on     :timestamp       not null
#

require 'digest/md5'

class GelImage < ActiveRecord::Base
  include ImageManipulation
  
  has_standard_fields
  has_many :pcrs
 
  validates_presence_of :name
  
  def display_name(options = {}) # :yields: String
    opt = {
      :type => nil 
    }.merge!(options.symbolize_keys)

    case opt
    when :for_select_list
      name
    else
      name
    end
  end

  
  #******************************************************
  # IMAGE FILE HANDLING STUFF #

  # almost copied straight from image.rb

  before_validation :record_image_details
  after_save :store_and_derive_files

  before_destroy :delete_all_files

  # checks for errors that the user has no control over, such as missing files and bad checksums
  def backend_validate
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
      "thumb" => {:x => "", :y => 160, :source => "original", :quality => 90, :sharpen => "-sharpen 2"} 
    }
  end

  def path_for(version, option = :web)
    path = (option == :file ? File.expand_path(GEL_IMAGE_FILE_PATH) : GEL_IMAGE_WEB_PATH)
    if version == "original"
      "#{path}/original/#{file_name}.#{self.file_type}"
    else
      "#{path}/#{version}/#{file_name}.jpg" if derived_files[version]
    end
  end

  private

  def record_image_details
    if @temp_file
      @details = im_identify(@temp_file.local_path)
      self.file_type = allowed_formats[@details[:type]]
      self.file_size = @temp_file.size
      self.width = @details[:width]
      self.height = @details[:height]
      self.file_md5 = Digest::MD5.hexdigest(@temp_file.read)
    end
  end

  def store_and_derive_files
    if @temp_file
      calc_file_name unless self.file_name? # file name does not change once the record is created
      begin
        logger.info "Storing #{path_for("original", :file)}"
        if @temp_file.instance_of?(Tempfile)
          FileUtils.copy(@temp_file.local_path, path_for("original", :file))
        else
          @temp_file.rewind # we already read the file to get the MD5, so i have to rewind
          File.open(path_for("original", :file), "wb") { |f| f.write(@temp_file.read) }
        end
        delete_derived_files
        create_derived_files
      rescue
        logger.info "Rescuing #store_and_derive_files"
        delete_all_files
        raise
      end
    end
  end

  ##* should add date-time checking, smart creation, 'force' option
  def create_derived_files
    logger.info "Time for #create_derived_files: " + Benchmark.measure{
    begin
      derived_files.each do |version, options|
        im_make_jpg(path_for(options[:source], :file), path_for(version, :file), options)
        raise "Failed to create #{version}" unless File.exists?(path_for(version, :file))
      end
    rescue
      logger.info "Rescuing #create_derived_files"
      delete_derived_files
      raise
    end
  }.to_s
  end

  def calc_file_name
    self.file_name = "#{self.id}_foo"
    self.class.update_all("file_name = '#{self.file_name}'", "id = #{self.id}")
  end

  def delete_derived_files
    derived_files.each_key do |version|
      delete_file(path_for(version, :file))
    end
  end

  def delete_all_files
    delete_derived_files
    delete_file(path_for("original", :file))
  end
    
  def delete_file(name)
    if (File.exists?(name) and not File.directory?(name))
      logger.info "Deleting #{name}"
      File.delete(name) 
    end
  end

end
