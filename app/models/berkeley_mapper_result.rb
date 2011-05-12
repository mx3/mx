# == Schema Information
# Schema version: 20090930163041
#
# Table name: berkeley_mapper_results
#
#  id         :integer(4)      not null, primary key
#  tabfile    :text(16777215)
#  proj_id    :integer(4)      not null
#  created_on :timestamp       not null
#

class BerkeleyMapperResult < ActiveRecord::Base
  has_standard_fields
  
  before_create :nuke_old_records
  
  def nuke_old_records
    self.class.delete_all(["created_on < ?", 10.minutes.ago])
  end
end
