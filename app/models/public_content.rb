# == Schema Information
# Schema version: 20090930163041
#
# Table name: contents
#
#  id              :integer(4)      not null, primary key
#  otu_id          :integer(4)
#  content_type_id :integer(4)
#  text            :text
#  is_public       :boolean(1)      default(TRUE), not null
#  pub_content_id  :integer(4)
#  revision        :integer(4)
#  proj_id         :integer(4)      not null
#  creator_id      :integer(4)      not null
#  updator_id      :integer(4)      not null
#  updated_on      :timestamp       not null
#  created_on      :timestamp       not null
#

class PublicContent < Content

  # We generate new content records to for full seperation of public/private content.  Since figures are tied to 
  # content we must duplicate them as well- to use cascading relationships its easier to duplicate content records than
  # try to keep the public content together with the working version
  # has_many :public_tags, :as => :addressable, :class_name => "Tag", :include => [:keyword, :ref], :order => 'refs.cached_display_name ASC', :conditions => 'keywords.is_public = true'
  
  validates_presence_of :pub_content_id
  
  belongs_to :content, :class_name => 'Content', :foreign_key => 'pub_content_id' # points to the original

  validate :check_record
  def check_record
    # override Content validation
    true
  end

end
