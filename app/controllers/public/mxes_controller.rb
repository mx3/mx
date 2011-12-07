class Public::MxesController < Public::BaseController

  include ActionView::Helpers::TextHelper

  before_filter :set_export_variables, :only => [:show_nexus, :show_tnt, :show_ascii, :as_file]

  def index
    list
    render :action => 'list'
  end

  def list
    @mx_pages, @mxes = paginate :mx, :per_page => 20,
    :order_by => 'name', :conditions => ['proj_id = ? AND is_public = true', @proj.id]
  end

  def show
    redirect_to :action => :show_grid_coding, :id => params[:id] and return
  end

  def show_trees
    @mx = Mx.find(params[:id]) 
    @trees = @mx.trees
    @no_right_col = true
    session['mx_view']  = 'show_trees'
    @show = ('show_trees') # not redundant with above- @show necessary for multiple display of items 
    render :action => :show
  end

  def show_ascii
    # has its own layout
    # see before_filter set_export_variables  
   @interleave_width = 30
    render :template => '/mx/export/show_ascii',  :layout =>  false
  end



  def show_nexus
    @mx = Mx.find(params[:id])  
    @chrs = @mx.chrs
    @otus = @mx.otus
    # @codings = @mx.codings
    @codings_mx = @mx.codings_mx

    @no_right_col = true
    session['mx_view']  = 'show_nexus'
    @show = ('show_nexus') # not redundant with above- @show necessary for multiple display of items 
    render :action => 'show'
  end

  def show_phylowidget
    @mx = Mx.find(params[:id])  
    @tree = Tree.find(params[:tree_id])

    @no_right_col = true
    session['mx_view']  = 'show_phylowidget'
    @show = ('show_phylowidget') # not redundant with above- @show necessary for multiple display of items 
    render :action => 'show'
  end

  def show_tnt
    @no_right_col = true
    session['mx_view']  = 'show_tnt'
    @show = ('show_tnt') # not redundant with above- @show necessary for multiple display of items 
    render :action => 'show'
  end

  def tnt_as_file
    @mx = Mx.find(params['id'])  
    @chrs = @mx.chrs
    @otus = @mx.otus
    @codings_mx = @mx.codings_mx

    f = render_to_string(:partial => "tnt", :layout => false)
    send_data(f, :filename => 'mx_matrix.tnt', :type => "application/rtf", :disposition => "attachment")
    # DO NOT USE REDIRECT/RENDER HERE
  end

  def show_otus
    @mx = Mx.find(params[:id]) 
    @otus = @mx.otus
    session['mx_view']  = 'show_otus'
    @show = ('show_otus') # not redundant with above- @show necessary for multiple display of items 
    render :action => :show
  end

  def show_chrs
    @mx = Mx.find(params[:id])  
    @chrs = @mx.chrs 
    @no_right_col = true
    session['mx_view']  = 'show_chrs'
    @show = ('show_chrs')
    render :action => 'show' 
  end

  # used in a couple of places
  def grid_coding_params
    @chrs = @mx.chrs
    @otus = @mx.otus
 
    @codings_mx = @mx.codings_mx

    session[:interleave_size] = params[:interleave_size] if params[:interleave_size]
    session[:interleave_size] ||= 20
  end

  def show_grid_coding
    @mx = Mx.find(params['id'])  
    grid_coding_params

    @no_right_col = true
    session['mx_view']  = 'show_grid_coding'
    @show = ('show_grid_coding') 
    render :action => 'show' 
  end

  # sloooow
  def show_grid_tags
    @mx = Mx.find(params['id'])  
    grid_coding_params

    @no_right_col = true
    session['mx_view']  = 'show_grid_tags'
    @show = ('show_grid_tags') 
    render :action => 'show' 
  end
 
  def set_export_variables
    @mx = Mx.find(params[:id])  
    @multistate_characters = @mx.chrs.that_are_multistate
    @continuous_characters = @mx.chrs.that_are_continuous
    @otus = @mx.otus
    @codings_mx = @mx.codings_mx
  end

end
