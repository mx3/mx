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

## ! note the images under svn control used for testing are corrupt in some weird way- they won't load

class ImageTest < ActiveSupport::TestCase
  # fixtures :images

  def setup
    $person_id = 1
    $proj_id = 1
  end

  # since the current image testing is trivial, and since 
  # getting imagemagick working can be hard, i've commented this out
  def test_new
    # foo = fixture_file_upload('/files/img_1.jpg', 'image/jpg')
    # @image = Image.new(:file => foo)
    # 
    # assert @image.save!   
  end  

end
