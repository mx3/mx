require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class ObjectRelationshipTest < ActiveSupport::TestCase

  def setup
    set_before_filter_vars
  end

  test "that interaction is required" do
    foo = ObjectRelationship.new
    assert !foo.valid?
  end

end
