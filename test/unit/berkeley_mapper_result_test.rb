# == Schema Information
# Schema version: 20090930163041
#
# Table name: berkeley_mapper_results
#
#  id         :integer(4)      not null, primary key
#  tabfile    :text(16777215)
#  proj_id    :integer(4)      not null
#  created_on :timestamp       not null
#

require File.expand_path(File.dirname(__FILE__) + "/../test_helper")


class BerkeleyMapperResultTest < ActiveSupport::TestCase
  fixtures :berkeley_mapper_results

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
