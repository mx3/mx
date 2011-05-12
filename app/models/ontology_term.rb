# OntologyTerms should typically be created via OntologyTerm.find_or_create_by_uri(some_uri) so that same terms are shared across usages

class OntologyTerm < ActiveRecord::Base  
  
end