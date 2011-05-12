# == Schema Information
# Schema version: 20090930163041
#
# Table name: news
#
#  id         :integer(4)      not null, primary key
#  news_type  :string(255)
#  body       :text
#  expires_on :date
#  proj_id    :integer(4)
#  title      :string(255)
#  is_public  :boolean(1)      not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#

class News < ActiveRecord::Base
   has_standard_fields # doesn't need proj_id !

  def set_proj
    #   override
  end

  belongs_to :proj
  validates_presence_of :body, :news_type, :creator_id, :updator_id, :created_on, :updated_on, :expires_on

  # add scopes for curent/public <- remove methods form Proj

  def self.current_app_news(kind = 'news')
    find(:all, :conditions => ["(expires_on > ?) and (proj_id is null) and (news_type = ?)", Time.now, kind], :order => "updated_on DESC")
  end


end

