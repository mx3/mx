class Public::ClaveController < Public::BaseController

  def index
    list
    render :action => 'list'
  end

  def list
    session[:multikey] = nil
    @multikeys = @proj.public_multikeys
    @claves = @proj.public_claves
  end
  
  def show
    @clave = Clave.find(params[:id])
    children = @clave.children(:order => :position)
    if children.size == 2
      @left = children[0]
      @right = children[1]
    end
    @parents = @clave.ancestors.reverse!
 
    redirect_to :action => :list and return if !@left && !@right 
  
    @left_text = Linker.new(:link_url_base => self.request.host, :proj_id => @proj.ontology_id_to_use, :is_public => true, :incoming_text => @left.couplet_text, :adjacent_words_to_fuse => 5).linked_text
    @right_text = Linker.new(:link_url_base => self.request.host, :proj_id => @proj.ontology_id_to_use, :is_public => true, :incoming_text => @right.couplet_text, :adjacent_words_to_fuse => 5).linked_text
    
    @left_future = @left.future
    @right_future = @right.future
    
  end
end
