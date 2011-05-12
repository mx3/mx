require 'ontology/ontology_methods'

class Public::SensuController < Public::BaseController

# verify :method => :post, :only => [ :search ],
#   :redirect_to => { :action => :index }

  def refs
    @refs = @proj.refs.used_in_sensus
  end
  
end




