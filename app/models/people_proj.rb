class PeopleProj < ActiveRecord::Base
  belongs_to :person
  belongs_to :proj
end
