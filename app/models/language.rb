# == Schema Information
# Schema version: 20090930163041
#
# Table name: languages
#
#  id              :integer(4)      not null, primary key
#  ltype           :string(128)
#  subtag          :string(4)
#  description     :string(1024)
#  suppress_script :string(256)
#  preferred_value :string(4)
#  tag             :string(64)
#  prfx            :string(255)
#  added           :date
#  deprecated      :date
#  comments        :text
#

class Language < ActiveRecord::Base
  
  has_many :parts, :dependent => :nullify
  has_many :refs, :dependent => :nullify
  has_many :serials,:dependent => :nullify
  
  validates_presence_of [:description, :ltype, :added]
  
  def display_name(options = {})
    description
  end
  
  def self.find_for_auto_complete(value)
    value.downcase!
    find_by_sql(["SELECT o.* FROM languages AS o 
      WHERE (
        ((o.ltype NOT LIKE  'redundant') AND (o.ltype NOT LIKE 'region')) AND
        ((o.description LIKE ?) OR
        (o.subtag LIKE ?) OR
        (o.id = ?))
      );", 
      "%#{value}%", "#{value}%", value.gsub(/.[\D\s]/, '') ]) 
  end
  
end

