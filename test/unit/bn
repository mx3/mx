# == Schema Information
# Schema version: 20090930163041
#
# Table name: chromatograms
#
#  id                 :integer(4)      not null, primary key
#  pcr_id             :integer(4)
#  primer_id          :integer(4)
#  protocol_id        :integer(4)
#  done_by            :string(255)
#  chromatograph_file :string(255)
#  result             :string(24)
#  seq                :text
#  notes              :text
#  proj_id            :integer(4)      not null
#  creator_id         :integer(4)      not null
#  updator_id         :integer(4)      not null
#  updated_on         :timestamp       not null
#  created_on         :timestamp       not null
#


require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

## ! note the images under svn control used for testing are corrupt in some weird way- they won't load

class ChromatogramTest < ActiveSupport::TestCase

  def setup
    $person_id = 1
    $proj_id = 1
    @primer1 = Primer.create!(:name => "FOO", :sequence => "ACT")
    @primer2 = Primer.create!(:name => "BAR", :sequence => "TCA")
  
    @specimen = Specimen.create!
    @extract = Extract.create!(:specimen => @specimen) 

    @pcr = Pcr.create!(:fwd_primer => @primer1, :rev_primer => @primer2, :extract => @extract)
  end

  def test_truth
    chromatogram = Chromatogram.new
    assert_kind_of Chromatogram,  chromatogram
  end

  def test_create_with_file
    foo = fixture_file_upload('/files/chromatograph_file.ab1', 'application/octet-stream' )
    @c = Chromatogram.new(:pcr => @pcr, :uploaded_data => foo,  :primer => @primer1, :result => "succeeded", :seq => "ACGGC")
    assert_equal true, @c.save 
  end  

  def test_create_without_file_fails
    @c = Chromatogram.new(:pcr_id => 1,  :primer_id => "1", :result => "succeeded", :seq => "ACGGC")
    assert !@c.save
  end  
  
end
