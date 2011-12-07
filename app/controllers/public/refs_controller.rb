class Public::RefsController < Public::BaseController

  def index
    list
    render :action => 'list'
  end

  def list
    if params['sort'] == 'full_citation'
      s = 'full_citation'
    else
      s = 'year' 
    end
    @ref_pages, @refs = paginate :ref, { :per_page => 15, :include => :projs,
      :conditions => [ 'projs.id =?', @proj ], :order => s }
    @sort = s
  end

  def show
    # should project check some how, or not...
    if params[:id] != nil && @ref = Ref.find(params[:id], :include => [:taxon_names, :projs])
    else
      flash[:notice] = "can't find that reference!"
      redirect_to :action => 'list'
    end
  end

  # TODO: Re-implement
  def list_by_author 
    if params[:name]
      @refs = @proj.refs.with_author_last_name(params[:name])  
      @target = 'name'
    else
      params[:letter] = 'A' if not params[:letter]   
      @refs = Ref.by_author_first_letter_and_proj_id(params[:letter], @proj.id) 
      @target = 'letter'                        
    end  
  end

  def list_simple
    @list_title = 'All references in this project' 
    @refs = @proj.refs
  end 

  def list_recent
    @refs = @proj.refs.recently_changed(3.months.ago).ordered_by_updated_on
    @list_title = 'References created or updated in the last 3 months' 
    render :action => :list_simple
  end

end
