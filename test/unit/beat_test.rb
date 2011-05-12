require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class BeatTest < ActiveSupport::TestCase

  def setup
    set_before_filter_vars
    @proj = Proj.find($proj_id) 
  end

  # test "that has_pulse method is recognized" do
  #  assert o = Otu.new(:name => 'Foo')
  #  assert o.save!
  #  assert_equal 1, o.beats.size
  # end

end
