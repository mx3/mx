# encoding: utf-8 

# == Schema Information
# Schema version: 20090930163041
#
# Table name: claves
#
#  id              :integer(4)      not null, primary key
#  parent_id       :integer(4)
#  otu_id          :integer(4)
#  couplet_text    :text
#  position        :integer(4)
#  link_out        :text
#  link_out_text   :string(1024)
#  edit_annotation :text
#  pub_annotation  :text
#  head_annotation :text
#  manual_id       :string(7)
#  ref_id          :integer(4)
#  l               :integer(4)
#  r               :integer(4)
#  is_public       :boolean(1)      not null
#  redirect_id     :integer(4)
#  proj_id         :integer(4)      not null
#  creator_id      :integer(4)      not null
#  updator_id      :integer(4)      not null
#  updated_on      :timestamp       not null
#  created_on      :timestamp       not null
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

require 'yaml'

class ClaveTest < ActiveSupport::TestCase
  fixtures :claves

  # id parent_id all_children
  # 1 --  6  
  # 2 1   4
  # 3 1   0
  # 4 2   0
  # 5 2   2
  # 6 5   0
  # 7 5   0
  
  # self.use_instantiated_fixtures  = true
  
  def setup
    $person_id = 1
    $proj_id = 1
  end
  
  def test_new
    @k = Clave.new
    @k.save
    assert_equal nil,  @k.parent_id 
  end
  
  def test_add_child
    @k = Clave.new
    @k.save
    
      @l = @k.children.create(:couplet_text => "left side")
      @m = @k.children.create(:couplet_text => "right side")
      @n = @m.children.create(:couplet_text => "left side")
  end
  
  def test_dupe
    key = Clave.find(1)
    assert_equal nil, key.parent_id
    assert_equal 7, Clave.find(:all).length
    assert key.dupe
    assert_equal 14, Clave.find(:all).size   
    assert_equal 2, Clave.find(:all, :conditions => 'parent_id is null').size
    assert_equal 'Name of key (COPY)', Clave.find(:all, :conditions => 'parent_id is null', :order => 'id')[1].couplet_text
  end

  def test_all_children
     key = Clave.find(1)
     assert_equal 6, key.all_children.size
     
     key2 = Clave.find(2)
     assert_equal 4, key2.all_children.size
     
     key3 = Clave.find(3)
     assert_equal 0, key3.all_children.size   
  end
  
  def test_insert_couplet
    key2 = Clave.find(5)
    assert_equal 2, key2.all_children.size
    
    ids = key2.insert_couplet

    assert_equal 'Child nodes, if present, are attached to this node.', Clave.find(ids[0]).couplet_text
    
    assert_equal 2, Clave.find(ids[0]).all_children.size
    assert_equal 0, Clave.find(ids[1]).all_children.size
    
    assert_equal Clave.find(6), Clave.find(ids[0]).children[0]
    
    assert_equal 5, Clave.find(ids[0]).parent_id 
    assert_equal ids[0], Clave.find(6).parent_id 
    assert_equal ids[0], Clave.find(7).parent_id 
    
    key3 = Clave.find(5)
    assert_equal 4, key3.all_children.size

  end

  def test_destroy_couplet
   assert_equal 0, Clave.find(4).all_children.size
   assert_equal 2, Clave.find(5).all_children.size
   assert_equal 4, Clave.find(2).all_children.size

   mykey = Clave.find(2)   
    
   assert_equal 4, mykey.all_children.size
   # puts key.to_yaml
   mykey.destroy_couplet
   
   key2 = Clave.find(2)
   
   assert_equal 2, key2.all_children.size
   
   assert_equal 2, Clave.find(6).parent_id
   assert_equal 2, Clave.find(7).parent_id

   assert_equal 2, Clave.find(2).all_children.size
  end
  
end
