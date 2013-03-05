class PeopleProj < ActiveRecord::Base
  self.primary_key = false
  belongs_to :person
  belongs_to :proj
end
