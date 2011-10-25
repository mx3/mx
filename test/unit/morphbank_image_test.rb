# == Schema Information
# Schema version: 20090930163041
#
# Table name: images
#
#  id               :integer(4)      not null, primary key
#  file_name        :string(64)
#  file_md5         :string(32)
#  file_type        :string(4)
#  file_size        :integer(4)
#  width            :integer(3)
#  height           :integer(3)
#  user_file_name   :string(64)
#  taken_on_year    :integer(2)
#  taken_on_month   :integer(1)
#  taken_on_day     :integer(1)
#  owner            :string(255)
#  ref_id           :integer(4)
#  technique        :string(12)
#  mb_id            :integer(4)
#  notes            :text
#  updated_on       :timestamp       not null
#  created_on       :timestamp       not null
#  creator_id       :integer(4)      not null
#  updator_id       :integer(4)      not null
#  proj_id          :integer(4)      not null
#  copyright_holder :string(255)
#  contributor      :string(255)
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class MorphbankImageTest < ActiveSupport::TestCase

  def setup
    $person_id = 1
    $proj_id = 1
  end

  def test_save_fails_without_height_and_width
    @mb_img  = MorphbankImage.new(:mb_id => 2)
    assert !@mb_img.save 
  end

  def test_save_passes_with_height_and_width
    t = MorphbankImage.find(:all).size

    @mb_img  = MorphbankImage.new(:mb_id => 2, :height => 10, :width => 10)
    assert @mb_img.save! 
    assert_equal t + 1, MorphbankImage.find(:all).size
  end

  def test_that_save_polling_morphbank_fails_when_no_morphbank_image_match
    @mb_img  = MorphbankImage.new(:mb_id => 9191919191919191)
    assert_raises(ActiveRecord::RecordInvalid) { @mb_img.save! }
  end

  def test_that_height_and_width_can_be_updated
    mb_img  = MorphbankImage.new(:mb_id => 2, :height => 10, :width => 10)
    assert mb_img.save! 
    mb_img.reload
    assert_equal 10, mb_img.height
    assert_equal 10, mb_img.width

    mb_img.height = 20
    mb_img.save!
    mb_img.reload

    assert_equal 20, mb_img.height

  end

end
