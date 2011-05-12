# encoding: utf-8 

# == Schema Information
# Schema version: 20090930163041
#
# Table name: authors
#
#  id             :integer(4)      not null, primary key
#  ref_id         :integer(4)      not null
#  position       :integer(4)
#  last_name      :string(255)     not null
#  first_name     :string(255)
#  title          :string(255)
#  initials       :string(8)
#  auth_is        :string(16)      default("author"), not null
#  use_initials   :boolean(1)
#  name_with_init :string(255)
#  join_name      :string(255)
#  namespace_id   :integer(4)
#  external_id    :integer(4)
#  creator_id     :integer(4)      not null
#  updator_id     :integer(4)      not null
#  updated_on     :timestamp       not null
#  created_on     :timestamp       not null
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class AuthorTest < ActiveSupport::TestCase
  
  fixtures :authors
 
  def test_render_names
    a = authors(:author_1)
    assert_equal 'F.-B. B. B.', a.first_name_initials  
    assert_equal 'Blorf, F.-B. B. B.', a.display_name
    assert_equal 'F.-B. B. B. Blorf', a.display_name_initials_first

    a2 = authors(:author_2)
    assert_equal 'F. B. B. B.', a2.first_name_initials  
    assert_equal 'Blorf, F. B. B. B.', a2.display_name
    assert_equal 'F. B. B. B. Blorf', a2.display_name_initials_first
    
    a3 = authors(:author_3)
    assert_equal 'F.', a3.first_name_initials  
    assert_equal 'Blorf, F.', a3.display_name
    assert_equal 'F. Blorf', a3.display_name_initials_first
    
    a4 = authors(:author_4)
    assert_equal '', a4.first_name_initials
    assert_equal 'Blorf', a4.display_name
    assert_equal 'Blorf', a4.display_name_initials_first
    
    a5 = authors(:author_5)
    assert_equal 'F.-B.', a5.first_name_initials 
    assert_equal 'Blorf, F.-B.', a5.display_name
    assert_equal 'F.-B. Blorf', a5.display_name_initials_first
  end
  
  def test_multibyte_names
    a = Author.new(:first_name => 'Ålbe', :last_name => 'Lindelöw')
    assert_equal('Å.', a.first_name_initials)
    
    a = Author.new(:first_name => 'Ålbe-Öunap', :last_name => 'Lindelöw')
    assert_equal('Å.-Ö.', a.first_name_initials)
    
    a = Author.new(:initials => 'ÅÖ', :last_name => 'Lindelöw')
    assert_equal('Å. Ö.', a.first_name_initials)
  end

  
    
end
  

