# == Schema Information
# Schema version: 20090930163041
#
# Table name: chromatograms
#
#  id                 :integer(4)      not null, primary key
#  pcr_id             :integer(4)
#  primer_id          :integer(4)
#  protocol_id        :integer(4)
#  done_by            :string(255)
#  chromatograph_file :string(255)
#  result             :string(24)
#  seq                :text
#  notes              :text
#  proj_id            :integer(4)      not null
#  creator_id         :integer(4)      not null
#  updator_id         :integer(4)      not null
#  updated_on         :timestamp       not null
#  created_on         :timestamp       not null


# NOTE! This model should be functional, but it is not presently used on a production server.
# At present a file is required.

class Chromatogram < ActiveRecord::Base
  has_standard_fields

  include ModelExtensions::DefaultNamedScopes

  belongs_to :pcr  
  belongs_to :primer
  belongs_to :protocol

  has_many :seqs, :through => :pcr

  has_attachment  :content_type => ['application/octet-stream'], # careful, likely some security issues here.
  :max_size => 10.megabytes, :path_prefix =>  '/public/files/' + CHROMATOGRAM_FILE_PATH.gsub(FILE_PATH, '') # has_attachment adds the Rails.root.to_s, so we need to strip it from our config, this may not always work for custom configs

  validates_presence_of :primer, :pcr, :filename
  validates_as_attachment # file is required now

  def display_name(options = {}) # :yields: String
    opt = {
      :type => nil
    }.merge!(options.symbolize_keys)

    case opt
    when :for_select_list
      primer.display_name + " " + pcr.display_name
    else
      filename
    end
  end

  def chromatogram_path
    CHROMATOGRAM_FILE_PATH + self.filename
  end

  # private
  # def base_part_of(filename)
  #   filename = File.basename(filename.strip)
  #   # remove leading period, whitespace and \ / : * ? " ' < > |
  #   filename = filename.gsub(%r{^\.|[\s/\\\*\:\?'"<>\|]}, '_')
  # end

end
