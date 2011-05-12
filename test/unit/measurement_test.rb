require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class MeasurementExaminedTest < ActiveSupport::TestCase
  
  def setup
    set_before_filter_vars
    @person =  Person.find($person_id) 
    @proj = Proj.find($proj_id) 

    @o = Otu.create!(:name => "foo")
  end



end
