# == Schema Information
# Schema version: 20090930163041
#
# Table name: content_templates_content_types
#
#  foo_id              :integer(4)      not null, primary key
#  content_type_id     :integer(4)      not null
#  content_template_id :integer(4)      not null
#  position            :integer(1)
#

class ContentTemplatesContentType < ActiveRecord::Base
  
  def self.primary_key() "foo_id" end
  belongs_to :content_template
  belongs_to :content_type
  acts_as_list :scope => :content_template

  validate :check_record
  def check_record
    if ContentTemplatesContentType.find(:first, :conditions => {:content_template_id => content_template_id, :content_type_id => content_type_id})
      errors.add(:content_type_id, "is already included in this template.")
    end
  end

end
