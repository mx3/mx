require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class SpecimenDeterminationTest < ActiveSupport::TestCase
  # fixtures :specimens, :people, :people_projs, :projs
  # self.use_instantiated_fixtures  = true
  
  def setup
    set_before_filter_vars
  end
 
  def test_sd_det_on_is_set_when_not_provided
    s = Specimen.new
    s.save!
    o = Otu.create!(:name => "foo")
    sd = SpecimenDetermination.new(:otu => o)
    assert s.specimen_determinations << sd
    assert sd.det_on 
    assert_equal sd.det_on.year, Time.now.year
  end
end

