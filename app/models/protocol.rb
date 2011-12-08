# == Schema Information
# Schema version: 20090930163041
#
# Table name: protocols
#
#  id          :integer(4)      not null, primary key
#  kind        :string(10)
#  description :text
#  proj_id     :integer(4)      not null
#  creator_id  :integer(4)      not null
#  updator_id  :integer(4)      not null
#  updated_on  :timestamp       not null
#  created_on  :timestamp       not null
#

class Protocol < ActiveRecord::Base

  KINDS =  ["extraction", "chromatogram", "clean", "PCR", "preparation", "other" ]

  has_standard_fields
  include ModelExtensions::DefaultNamedScopes

  has_many :pcrs, :dependent => :nullify
  has_many :primers, :dependent => :nullify
  has_many :chromatograms, :dependent => :nullify
  has_many :extracts, :dependent => :nullify
  has_many :protocol_steps, :dependent => :destroy
  has_many :lots, :foreign_key => :preparation_protocol_id
  has_many :specimens, :foreign_key => :preparation_protocol_id

  validates_presence_of :description

  def display_name(options = {})
    opt = {
      :type => nil
    }.merge!(options.symbolize_keys)
    
    s = ''
   
    case opt[:type]
    when :selected
      description
    when :for_select_list
      description[0..40]
    else
      description
    end
  end

end
