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

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class ContentTest < ActiveSupport::TestCase
  fixtures :contents, :images, :otus
  
  def setup
    $proj_id = 1
    $person_id = 1
  end
  
  def test_validation
    @otu = Otu.create!(:name => "Foosaurusrex")
    @ct = ContentType.create!(:name => 'bedtimestory')
    @text = "It was a dark and stormy night.  Really, it was."

    @content = Content.new( :text => @text, :content_type => @ct)
    assert !@content.valid?
    assert @content.errors.invalid?(:otu)

    @content.otu = @otu
    assert true, @content.valid?
  end

  def test_that_text_gets_sanitized
    text = "Some text <script type=\"text/javascript\"> foo(); </script> with nasty stuff."
    content = contents(:cons1)
    otu = Otu.new(:name => 'foo')
    ct = ContentType.new(:name => 'bar')
    content.update_attributes!(:text => text, :otu => otu, :content_type => ct)
    content.reload
    assert_equal("Some text  with nasty stuff.", content.text)
  end
  
  # should probably be tested on the mixed-in sanitize method directly...
  def test_that_sanitize_does_not_mangle_ref_tags_and_such
    text = "Hi <ref id=\"\">2007</ref> ho <ref id=\"12345\">Bar 2006</ref> fum<ref id=\"\"> Foo</ref>."
    content = contents(:cons1)
    otu = Otu.new(:name => 'foo')
    ct = ContentType.new(:name => 'bar')
    content.update_attributes!(:text => text, :otu => otu, :content_type => ct)
    content.reload
    assert_equal(text, content.text)
  end

  def setup_for_publish_tests
    @otu = Otu.create!(:name => "Foosaurusrex")
    @ct = ContentType.create!(:name => 'bedtimestory')
    @text = "It was a dark and stormy night.  Really, it was."
    @content = Content.create!(:otu => @otu, :text => @text, :content_type => @ct)
  end

  def test_publish_content_without_figures
    setup_for_publish_tests
    assert_equal false, @content.is_published
    
    assert_equal true, @content.publish

    @content.reload 
    assert_equal @content.public_version.pub_content_id, @content.id
    assert_equal true, @content.is_published

    assert_equal @text, @content.public_version.text
    assert_equal 1, @content.public_version.revision

    @content.figures.reload
    assert_equal 0, @content.figures.size
  end

  def test_publish_content_with_figures
    setup_for_publish_tests
    f = Figure.create(:addressable_id => @content.id, :addressable_type => "Content", :image_id => 1)

    assert_equal 1, @content.figures.size
    assert_equal true, @content.publish

    @content.reload 
    
    assert_equal 1, @content.figures.size
    assert_equal 1, @content.public_version.figures.size 
    assert_equal @text, @content.public_version.text
  end

  def test_publish_content_with_figures_added_then_removed_and_published
    setup_for_publish_tests

    f = Figure.create(:addressable_id => @content.id, :addressable_type => "Content", :image_id => 1)

    assert_equal 1, @content.figures.size
    assert_equal true, @content.publish

    @content.reload 
    
    assert_equal 1, @content.figures.size
    assert_equal 1, @content.public_version.figures.size

    # remove the figure
    @content.figures[0].destroy
    @content.reload 
    assert_equal 0, @content.figures.size

    assert_equal true, @content.publish
    @content.reload 

    assert_equal 0, @content.figures.size
    assert_equal 0, @content.public_version.figures.size
    assert_equal 1, @content.public_version.revision # text hasn't changed
  end

  def setup_for_transfer_tests
    @ct = ContentType.create(:name => 'foo')
    @otu = Otu.new(:name => 'Foosorusrex')
    @otu.save!

    @text = 'Blorfing in the foo one day, it smorfed a gloop.'
    @content = Content.new(:content_type => @ct, :text => @text)
    @otu.contents << @content
    @content.save!
    
    assert_equal true, !@ct.blank?
    assert_equal true, !@otu.blank?

    assert_equal @text, @content.text
    assert_equal 1, @otu.contents.size

    @other_otu = Otu.create(:name => 'Titanofoosorusrex')
    assert_equal 0, @other_otu.contents.size
  end

  def test_transfer_to_other_otu_when_content_type_not_present_in_other_otu_with_delete
    setup_for_transfer_tests
   
    assert_equal true, @content.transfer_to_otu(@other_otu) 
    assert_equal 0, @otu.contents.size
    @other_otu.contents.reload
    assert_equal 1, @other_otu.contents.size
    assert_equal @text, @other_otu.contents[0].text
  end

  def test_transfer_to_other_otu_when_content_type_present_in_other_otu_with_delete
    setup_for_transfer_tests  
    other_text = "This comes first!"
    content = Content.create(:otu => @other_otu, :text => other_text, :content_type => @ct)
    assert_equal other_text, content.text

    assert_equal true, @content.transfer_to_otu(@other_otu) 
    assert_equal 0, @otu.contents.size
    @other_otu.contents.reload
    assert_equal 1, @other_otu.contents.size
    assert_equal other_text + " [Transfered from OTU #{@otu.id}: #{@text}]",  @other_otu.contents[0].text
  end

  def test_transfer_to_other_otu_when_content_type_present_in_other_otu_without_delete
    setup_for_transfer_tests  
    other_text = "This comes first!"
    content = Content.create(:otu => @other_otu, :text => other_text, :content_type => @ct)
    assert_equal other_text, content.text

    assert_equal true, @content.transfer_to_otu(@other_otu, false)
    @otu.contents.reload
    assert_equal 1, @otu.contents.size
    assert_equal @text, @otu.contents[0].text
    @other_otu.contents.reload
    assert_equal 1, @other_otu.contents.size
    assert_equal other_text + " [Transfered from OTU #{@otu.id}: #{@text}]",  @other_otu.contents[0].text
  end

  def test_transfer_to_other_otu_when_content_type_not_present_with_figs_with_delete
    setup_for_transfer_tests
    f = Figure.create(:addressable_id => @content.id, :addressable_type => "Content", :image_id => 1)

    assert_equal 1, @content.figures.size
    assert_equal true, @content.transfer_to_otu(@other_otu)

    @otu.contents.reload
    @other_otu.contents.reload
    
    assert_equal 1, @content.figures.size
    assert_equal 0, @otu.contents.size
    assert_equal 1, @other_otu.contents.size
    assert_equal 1, @other_otu.contents[0].figures.size
  end

  def test_transfer_to_other_otu_when_content_type_not_present_with_tags_with_delete
    setup_for_transfer_tests
    k = Keyword.create!(:keyword => "FOO!")
    t = Tag.create(:addressable_id => @content.id, :addressable_type => "Content", :keyword => k)

    assert_equal 1, @content.tags.size
    assert_equal true, @content.transfer_to_otu(@other_otu)
    
    @otu.contents.reload
    @other_otu.contents.reload

    assert_equal 1, @content.tags.size
    assert_equal 0, @otu.contents.size
    assert_equal 1, @other_otu.contents.size
    assert_equal 1, @other_otu.contents[0].tags.size
    assert_equal k.keyword, @other_otu.contents[0].tags[0].keyword.keyword
  end

  def test_transfer_to_other_otu_when_content_type_present_with_tag_present_with_delete
    setup_for_transfer_tests
    
    tag_notes = "This comes second!"
    other_tag_notes = "This comes comes first!"
    other_content = Content.create(:otu => @other_otu, :text => @text, :content_type => @ct)
    
    k = Keyword.create!(:keyword => "FOO!")

    t = Tag.create(:addressable_id => @content.id, :addressable_type => "Content", :keyword => k, :notes => tag_notes)
    other_t = Tag.create(:addressable_id => other_content.id, :addressable_type => "Content", :keyword => k, :notes => other_tag_notes)

    assert_equal 1, @content.tags.size
    assert_equal 1, other_content.tags.size
    assert_equal true, @content.transfer_to_otu(@other_otu)

    @otu.contents.reload
    @other_otu.contents.reload

    # assert_equal nil, @content # should be destoyed
    assert_equal 1, @other_otu.contents[0].tags.size
    assert_equal "#{other_tag_notes} [Transfered from OTU #{@otu.id}: #{tag_notes}]", @other_otu.contents[0].tags[0].notes
  end

  def test_transfer_to_other_otu_when_content_type_not_present_with_tag_present_without_delete
    setup_for_transfer_tests
    tag_notes = "This comes second!"

    k = Keyword.create!(:keyword => "FOO!")
    t = Tag.create(:addressable_id => @content.id, :addressable_type => "Content", :keyword => k, :notes => tag_notes)

    assert_equal 1, @content.tags.size
    assert_equal 0, @other_otu.contents.size
    assert_equal true, @content.transfer_to_otu(@other_otu, false)

    @otu.contents.reload
    @other_otu.contents.reload

    assert_equal 1, @otu.contents.size # should still be here
    assert_equal 1, @other_otu.contents.size # should have new one

    assert_equal 1, @otu.contents[0].tags.size # should still have one
    assert_equal 1, @other_otu.contents[0].tags.size # new content should too
  end

  def test_publish_when_published
    @proj = Proj.find($proj_id)
    @proj.contents.destroy_all
    setup_for_publish_tests
    @proj.reload
    assert_equal 1, @proj.contents.size
    assert @content.publish
    @proj.reload
    @content.reload   
    assert_equal 2, @proj.contents.size
    assert @content.publish
    @proj.reload
    @content.reload 
    assert_equal 2, @proj.contents.size
  end 

  def test_public_version
    setup_for_publish_tests
    assert !@content.public_version
    assert @content.publish
    @content.reload
    assert @content.public_version
    assert_equal PublicContent, @content.public_version.class
  end
end
