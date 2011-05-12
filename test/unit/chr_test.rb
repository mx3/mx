# == Schema Information
# Schema version: 20090930163041
#
# Table name: chrs
#
#  id               :integer(4)      not null, primary key
#  name             :string(255)     not null
#  cited_in         :integer(4)
#  cited_page       :string(64)
#  cited_char_no    :string(4)
#  revision_history :text
#  syn_with         :integer(4)
#  doc_char_code    :string(4)
#  doc_char_descr   :text
#  short_name       :string(6)
#  notes            :text
#  continuous       :boolean(1)
#  ordered          :boolean(1)
#  position         :integer(4)
#  proj_id          :integer(4)      not null
#  creator_id       :integer(4)      not null
#  updator_id       :integer(4)      not null
#  updated_on       :timestamp       not null
#  created_on       :timestamp       not null
#


require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class ChrTest < ActiveSupport::TestCase
  fixtures :chrs, :chr_states, :codings
  
  def setup
    set_before_filter_vars
   @chr = Chr.new(:name => "Foo")
    @chr.save
  end

  def test_truth
    assert_kind_of Chr, @chr
  end
  
  # see multikey for over view of input
  def test_by_states
     assert_equal 1, Chr.by_states([11]).size
     assert_equal 1, Chr.by_states([11, 11]).size
     assert_equal 1, Chr.by_states([11, 12]).size
     assert_equal 3, Chr.by_states([11, 13, 15]).size
  end

  def test_destroy
    assert @chr.destroy
  end

  def test_that_destroying_chr_removes_from_chr_group_nicely
    @cg = ChrGroup.new(:name => "Bar")
    @cg.save
    @cg.add_chr(@chr)
    @cg.reload
    assert_equal 1, @cg.chrs.count
    assert @chr.destroy
    @cg.reload
    assert_equal 0, @cg.chrs.count
  end
   

  def dont_test_microformat_parser
    @file = fixture_file_upload('/test_files/chr_micro_format.txt', 'text/plain')
    @proj = Proj.find($proj_id)
    # wipe all the characters
    @proj.chrs.each do |c|
      c.destroy
    end

    @proj.reload
    assert_equal 0, @proj.chrs.size

    Chr.read_microformat(:file => @file)
    assert_equal 3, @proj.chrs.size

  end

end
