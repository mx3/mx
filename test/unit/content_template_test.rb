# == Schema Information
# Schema version: 20090930163041
#
# Table name: content_templates
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)     not null
#  is_default :boolean(1)      not null
#  is_public  :boolean(1)      not null
#  proj_id    :integer(4)      not null
#  creator_id :integer(4)      not null
#  updator_id :integer(4)      not null
#  updated_on :timestamp       not null
#  created_on :timestamp       not null
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class ContentTemplateTest < ActiveSupport::TestCase
  fixtures :content_templates, :contents, :images, :otus
  def setup
    $proj_id = 1
    $person_id = 1
  end
  
  def test_create
    ct = ContentTemplate.new(:name => 'foo')
    assert ct.valid?
    assert_equal true, ct.save
  end

  def test_add_content_types
    ct = ContentTemplate.create!(:name => 'foo')
    assert_equal 0, ct.content_types.size

    ctype = ContentType.create!(:name => 'blorf')
    ct.content_types << ctype
    ctype.save
    ct.reload

    assert_equal 1, ct.content_types.size
  end

  def test_add_only_one_of_each_content_type
    ct = ContentTemplate.create!(:name => 'foo')

    ctype = ContentType.create!(:name => 'blorf')
    ct.content_types << ctype
    ctype.save
    ct.reload
    assert_equal 1, ct.content_types.size

    # how else to do this type of test?
    begin
      ct.content_types << ctype
      assert false
    rescue
      assert true
    end

  end

  def test_destroy_with_content_types
    ct = ContentTemplate.create!(:name => 'foo')
    ct.content_types << ContentType.create!(:name => 'blorf')
    ct.reload

    assert_equal 1, ct.content_types.size
    assert ct.destroy
  end

  def test_available_mx_content_types
    ct = ContentTemplate.create!(:name => 'foo')
    cont_type = "ContentType::#{ContentType.custom_types[0]}".constantize.create!(:sti_type => ContentType.custom_types[0])

    assert_equal  ContentType.custom_types.size, ct.available_mx_content_types.size 

    ct.content_types << cont_type
    ct.save
    ct.reload
    assert_equal 1, ct.mx_content_types.size 

    assert_equal ContentType.custom_types.size - 1, ct.available_mx_content_types.size  
  end
  
  def test_mx_content_types
    ct = ContentTemplate.create!(:name => 'foo')
    cont_type = "ContentType::#{ContentType.custom_types[0]}".constantize.create!(:sti_type => ContentType.custom_types[0])
    assert_equal 0, ct.content_types.size
    ct.content_types << cont_type
    ct.save
    ct.reload
    assert_equal 1, ct.mx_content_types.size
  end


  def test_available_text_content_types
    $proj_id = 999 # make sure were in a clean project
    ct = ContentTemplate.create!(:name => 'foo')
    assert_equal 0, ct.available_text_content_types.size
    a = ContentType.create!(:name => 'foo')
    b = ContentType.create!(:name => 'bar')
    c = ContentType.create!(:name => 'blorf')
    
    assert_equal 3, ct.available_text_content_types.size
    ct.content_types << a
    ct.reload
    assert_equal 1, ct.content_types.size
    assert_equal 2, ct.available_text_content_types.size
  end

  def test_text_content
    o = Otu.create!(:name => 'foo')
   
    ctype1 = ContentType.create!(:name => 'foo')
    ctype2 = ContentType.create!(:name => 'bar')

    cont1 = Content.create!(:otu => o, :content_type => ctype1, :text => "Wizzle wozzle.")
    cont2 = Content.create!(:otu => o, :content_type => ctype2, :text => "Wozzle wizzle.")
      
    assert_equal 2, o.contents.size

    ctemp = ContentTemplate.create!(:name => "blorf")
    ctemp.content_types << ctype1
    ctemp.content_types << ctype2

    ctemp.reload
    assert_equal 2, ctemp.text_content_types.size
    assert_equal 2, ctemp.content_types.size

    assert_equal 2, ctemp.text_content(o).size

    # note that ContentTemplate.text_content returns {ContentType.id => Content .. } 

    assert_equal cont1, ctemp.text_content(o)[ctype1.id] # keys are ContentType.ids
    assert_equal cont2, ctemp.text_content(o)[ctype2.id]
  end

  def test_publish
    $proj_id = 2912
    o = Otu.create!(:name => 'foo')
    ctype1 = ContentType.create!(:name => 'foo', :is_public => true)
    ctype2 = "ContentType::#{ContentType.custom_types[0]}".constantize.create!(:sti_type => ContentType.custom_types[0])
  
    assert_equal true, ctype2.is_public # custom types are public by default

    ctemp = ContentTemplate.create!(:name => "blorf")
    ctemp.content_types << ctype1
    ctemp.content_types << ctype2

    cont1 = Content.create!(:otu => o, :content_type => ctype1, :text => "Wizzle wozzle.", :is_public => true)

    ctemp.reload
    o.reload
    assert ctemp.publish(o)
    o.reload
    assert_equal 1, Content.by_otu(o).that_are_published.in_content_template(ctemp).size # asserts that no attempt to publish custom content types is made for custom content types
  end

end

