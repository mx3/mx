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

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class NewsTest < ActiveSupport::TestCase
  
  fixtures :news
  fixtures :people
  
  def setup
    $person_id = 1 # is admin
  end
  
  def  test_save
    assert_equal 1, News.current_app_news.size
    # create news outside proj
    @news = News.new
    @news.body = 'This is NEW news.'
    @news.news_type = 'news'
    @news.expires_on = 2.days.from_now 
    @news.created_on = Time.now 
    @news.updated_on = Time.now 
    assert @news.save! 
    assert_equal 2, News.current_app_news.size

    
    # create news inside proj
    $proj_id = 1
    @news2 = News.new
    @news2.body = 'This is some project 1 news.'
    @news2.news_type = 'news'
    @news2.expires_on =  2.days.from_now 
    @news2.created_on = Time.now 
    @news2.updated_on = Time.now
    @news2.proj_id = 1

    assert @news2.save! 
    assert_equal 3, Proj.find(1).news.size
    
  end
  
  def test_current_app_news
    assert_equal 1, News.current_app_news.size
  end

  

end
