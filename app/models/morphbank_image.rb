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

include RubyMorphbank

class MorphbankImage < Image

  validates_presence_of :mb_id, :height, :width
  validates_uniqueness_of :mb_id, :scope => :proj_id, :message => ' image is already present in the project.'

  BASE_URL = 'http://morphbank.net/' # trailing slash required
  SIZE_TO_TYPE = {:original => 'tiff', :medium => 'jpg', :big => 'jpeg', :thumb => 'jpg'}

  # override validation for file handling in Image
  validate :check_record
  def check_record
    true
  end

  before_validation :record_image_details
  after_save :store_and_derive_files
  before_destroy :delete_all_files

  def record_image_details
    # cache height/width here
    if self.width.blank? || self.height.blank?
      begin
        x = RubyMorphbank.metadata_hash_for_one_image(self.mb_id)
        if !x.nil? && !x['width'].blank? && !x['height'].blank? && (x['width'].to_i > 0) && (x['height'].to_i > 0)     
          self.width = x['width']
          self.height = x['height']
          return true
        else 
          return false
        end
      rescue REXML::ParseException
        return false
      end
    end
    true 
  end

  def store_and_derive_files
    true
  end

  def delete_all_files
    true
  end

  # If the data from MB that are persisted in mx is updated this can be 
  # modified to update all the persisted metadata in mx.
  # See validation code for the actual MB requests 
  # TODO: print a warning, don't crash, if the image is not found in MBexit
  def self.poll_MB_for_metadata_updates
    begin
      MorphbankImage.transaction do
        puts "updating: "
        MorphbankImage.find(:all, :conditions => 'mb_id is not null and mb_id != ""').each do |i|
          print i.mb_id
          $proj_id = i.proj_id
          $person_id = i.creator_id

          x = RubyMorphbank.metadata_hash_for_one_image(i.mb_id)
          if !x.nil? && !x['width'].blank? && !x['height'].blank? && (x['width'].to_i > 0) && (x['height'].to_i > 0)     
            print " [#{x['width']}, #{x['height']}]"
         
            i.update_attributes(:width => x['width'].to_i, :height => x['height'].to_i)
            print " ok\n"      
          else
            print " FAILED\n"
          end
        end
      end
      true
    rescue
      raise
    end   
  end

end
