ENV["RAILS_ENV"] = "test"
ENV["RAILS_ROOT"] = File.expand_path("../", File.dirname(__FILE__))

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require File.expand_path(File.dirname(__FILE__) + '/blueprints')

# include #fixture_file_upload
# TODO: R3 check for alternatives
include ActionDispatch::TestProcess

class ActiveSupport::TestCase
  # Reset the Machinist cache before each test.
  setup { Machinist.reset_before_test }

  # These fixtures are required for all functional tests. TODO: scope for functionals only?
  fixtures :people, :projs #, :people_projs

  # can be outside class and still work...but what's best?
  def login # a pseudo login- sets a session to have a valid user such that protected controllers can be called
    @p = Person.find(4)

    @request.session[:person] = @p
    @request.session['proj_id'] = Proj.find(1).id
    @proj = Proj.find(@request.session['proj_id'])
    @proj.people << @p
    @proj.save!
    $proj_id = @proj.id
    true
  end

  # def select_proj(proj = '1')
    # a stub
  # end

  def set_before_filter_vars(proj = 1, person = 1)
    $proj_id = proj
    $person_id = person
  end

end

# added by kpd
ActiveRecord::Base.connection.update('SET FOREIGN_KEY_CHECKS = 0')
