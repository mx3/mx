class Public::RepositoryController < Public::BaseController
  def index
    list
    render :action => 'list'
  end

  def list
    @repositories = Repository.for_visible_taxon_names(@proj) 
  end

end
