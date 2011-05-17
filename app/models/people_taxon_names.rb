class PeopleTaxonName < ActiveRecord::Base
  set_primary_key false
  belongs_to :person
  belongs_to :taxon_name
end
