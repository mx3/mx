require File.expand_path(File.dirname(__FILE__) + "/../test_helper")
require File.expand_path(File.dirname(__FILE__) + "/../../lib/ipt")

class IptTest < ActiveSupport::TestCase

  def setup
    set_before_filter_vars
    @proj = Proj.find($proj_id) 
  end

  test "something" do 
    assert true # setup_for_ipt_related_tests
  end

end
