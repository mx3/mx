class Public::ChrsController < Public::BaseController

  def index
    
  end
  
  def show
    id = params['id']
    id ||= params['chr']['id'] if params['chr'] # for autocomplete/ajax picker use
    id ||= params['chr_to_find']['id'] if params['chr_to_find'] # for ajax picker use 
    @chr = Chr.find(id, :include => 'chr_states')
  
  end

end



