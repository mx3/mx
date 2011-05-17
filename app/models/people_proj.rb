class PeopleProj < ActiveRecord::Base
  set_primary_key false
  belongs_to :person
  belongs_to :proj
end
