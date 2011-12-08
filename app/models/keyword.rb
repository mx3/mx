# == Schema Information
# Schema version: 20090930163041
#
# Table name: keywords
#
#  id          :integer(4)      not null, primary key
#  keyword     :string(255)     not null
#  shortform   :string(6)
#  explanation :text
#  is_public   :boolean(1)
#  html_color  :string(6)
#  proj_id     :integer(4)      not null
#  creator_id  :integer(4)      not null
#  updator_id  :integer(4)      not null
#  updated_on  :timestamp       not null
#  created_on  :timestamp       not null
#

class Keyword < ActiveRecord::Base
  has_standard_fields
  include ModelExtensions::DefaultNamedScopes

  has_many :tags, :dependent => :destroy, :include => :ref, :order => 'refs.cached_display_name'
  
  validates_uniqueness_of :keyword, :scope => 'proj_id'
  validates_presence_of :keyword  
  validates_length_of :shortform, :in => 1..6, :allow_blank => true
  validates_length_of :html_color, :is => 6, :allow_blank => true

  scope :used_in_a_tag, lambda {|*args| {:conditions => "id IN (SELECT keyword_id from tags where keyword_id is not null and keyword_id != '')" }}

  # should make this a mixin sensu StandardFields, because it will get use everywhere
  # Part.find(:all).tagged_with_keyword(12)
  scope :tagged_with_keyword, lambda {|*args| {:conditions => ["id IN (SELECT addressable_id FROM tags WHERE tags.addressable_type = 'Keyword' AND keyword_id = ?)", (args.first ? args.first : -1)]}}    
  scope :that_are_xrefs, :conditions => 'is_xref == 1'

  validate :check_record
  def check_record
    if not html_color.blank?
      errors.add(:html_color, "must be 6 characters, 0-9, a-f only") if html_color.size != 6
    end      
  end
 
  def display_name(options = {})
     @opt = {
      :type => :list # :list, :head, :dropdown, :select, :sub_select, :simple
     }.merge!(options.symbolize_keys)
    case @opt[:type]
      when :simple
       self.keyword 
     else # :list 
       html_color.blank? ? keyword : "<span style=\"background: ##{html_color}; padding: 0 .2em;\">#{keyword}</span>".html_safe
     end
  end
  
end
