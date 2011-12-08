# == Schema Information
# Schema version: 20090930163041
#
# Table name: standard_view_groups
#
#  id               :integer(4)      not null, primary key
#  name             :string(255)
#  notes            :text
#  other_identifier :string(32)
#  proj_id          :integer(4)      not null
#  updated_on       :timestamp       not null
#  created_on       :timestamp       not null
#  creator_id       :integer(4)      not null
#  updator_id       :integer(4)      not null
#

class StandardViewGroup < ActiveRecord::Base
  has_standard_fields
  include ModelExtensions::DefaultNamedScopes


  has_and_belongs_to_many :standard_views
 
  def display_name(options = {}) # :yields: String
    opt = {
     :type => nil
    }.merge!(options.symbolize_keys)
    s = ''
    case opt[:type]
    when :selected
      name
    when :for_select_list
      name
    else
      name
    end
  end

end
