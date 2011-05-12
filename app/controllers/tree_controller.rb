class TreeController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
     @trees_pages, @trees = paginate :trees, :per_page => 20, :conditions => "(proj_id = #{@proj.id})"
  end

  def show
    id = params[:tree][:id] if params[:tree] # for autocomplete/ajax picker use
    id ||= params[:id]
    @tree = Tree.find(id)
    @no_right_col = true
    session['tree_view']  = 'show'
    @show = ['show_default'] # array of partials to render 
  end

  def show_phylowidget
    @tree = Tree.find(params[:id])
    session['tree_view']  = 'show_phylowidget'
    @show = ['show_phylowidget'] # array of partials to render
    @no_right_col = true
    render :action => 'show'
  end

  def show_nested_set
    @tree = Tree.find(params[:id])
    session['tree_view']  = 'show_nested_set'
    @show = ['show_nested_set'] # array of partials to render
    @no_right_col = true
    render :action => 'show'
  end


  def new
    @tree = Tree.new
  end

  def create
    @tree = Tree.new(params[:tree])
    @ds = DataSource.find(params[:tree][:data_source_id]) if params[:tree] && !params[:tree][:data_source_id].blank?
    @tree.data_source_id = @ds.id if @ds # for some reason this is the only way it works, DON'T do @tree.data_source = @ds
	
    begin 
      if @tree.save
        flash[:notice] = 'Tree was successfully created.'
        redirect_to :action => 'list' and return
      else
        render :action => 'new'
      end
    rescue ParseError => e
      flash[:notice] = "Problem parsing the string #{e}."
      render :action => 'new'
    end
  end

  def edit
    @tree = Tree.find(params[:id])
  end

  def update
    
    @tree = Tree.find(params[:id])
    begin
      # update_attributes doesn't work when data_source_id is included?!, maybe due to Tree filters
	  ds = DataSource.find(params[:tree][:data_source_id]) if params[:tree] && !params[:tree][:data_source_id].blank?
      ds = DataSource.find(params[:ds][:id]) if params[:ds] && !params[:ds][:id].blank?
      @tree.tree_string = params[:tree][:tree_string]
      @tree.notes = params[:tree][:notes]
      @tree.name = params[:tree][:name]
      @tree.data_source_id = ds.id if ds
      @tree.save!
      flash[:notice] = 'Tree was successfully updated.'
      
      redirect_to :action => 'show', :id => @tree.id and return
    rescue  ParseError => e
      flash[:notice] = "Problem parsing the string #{e}."
      render :action => 'edit' and return
    end
  end

  def destroy
    Tree.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def auto_complete_for_tree
    @tag_id_str = params[:tag_id]
    value = params[@tag_id_str.to_sym]

    conditions = ["(trees.tree_string LIKE ? OR trees.name LIKE ? OR trees.id = ?) and proj_id = ?",  "%#{value}%", "%#{value}%", value, @proj.id]
    
    @trees = Tree.find(:all, :conditions => conditions, :limit => 35,
       :order => 'trees.name')
    render(:inline => "<%= auto_complete_result_with_ids(@trees, 'format_obj_for_auto_complete', @tag_id_str) %>")
  end

  def phylowidget
    @t = Tree.find(params[:id])
  end

  def test
    @t = Tree.find(params[:id])
    @bn = @t.root_tree_node
  
    @root = @t.root_tree_node
  end

  # proof of concept for TB 2 trees
  def test2
    uri = 'http://dbhack1.nescent.org/cgi-bin/phylows.pl/phylows/tree/TB:1999'
    # @x = Net::HTTP.get_response(URI.parse(uri)).body
    @d = Nexml::Document.new(:url => uri)
  end

  def _select_node
    if !params[:depth].blank? # we'll select the fist node from a given depth
      @node = Tree.find(params[:tree_id]).nodes_at_depth(params[:depth])[0]
    else
      @node = TreeNode.find(params[:id]) # the node you clicked on, should always get centered on 2
    end

    respond_to do |format|
      # shouldn't hit here
      format.html { 
        flash[:notice] = "Shouldn't be called with non AJAX method."
        render :action => :test, :id => @node.tree_id and return
      }
      format.js {
        render :update do |page|
          case params[:col_id].to_i
          when 1 
            # set 1 to parent
            page.replace_html :c1, :partial => 'atv_col_content', :locals => {:col_id => 1, :node => @node.parent.parent}  
            page.replace_html :c2, :partial => 'atv_col_content', :locals => {:col_id => 2, :node => @node.parent}  
            # clear 3
            page.replace_html :c3, :partial => 'atv_col_content', :locals => {:col_id => 3, :node => nil}  
          when 2..3
            # set 1 to parent of parent
            page.replace_html :c1, :partial => 'atv_col_content', :locals => {:col_id => 1, :node => @node.parent.parent}  
            # set 2 to parent 
            page.replace_html :c2, :partial => 'atv_col_content', :locals => {:col_id => 2, :node => @node.parent}  
            # set 3
            page.replace_html :c3, :partial => 'atv_col_content', :locals => {:col_id => 3, :node => @node} 
          end

          flash.discard
          end and return        
        }
      end
  end
  
  
end
