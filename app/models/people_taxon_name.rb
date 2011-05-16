class PeopleTaxonName < ActiveRecord::Base
  belongs_to :person
  belongs_to :taxon_name
end
