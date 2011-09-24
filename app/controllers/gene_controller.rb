class GeneController < ApplicationController
  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }
     
  def index
    list
    render :action => 'list'
  end

  def list_params
    @gene_pages, @genes = paginate :gene, :per_page => 30, :order_by => 'position, name', :conditions => ['proj_id = (?)', @proj.id]
  end

  def list
    list_params
     if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def show
    id = params[:gene][:id] if params[:gene]
    id ||= params[:id]
    @gene = Gene.find(id)
  end

  def new
    @gene = Gene.new
  end

  def create
    @gene = Gene.new(params[:gene])
    if @gene.save
      flash[:notice] = 'Gene was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @gene = Gene.find(params[:id])
  end

  def update
    @gene = Gene.find(params[:id])
    if @gene.update_attributes(params[:gene])
      flash[:notice] = 'Gene was successfully updated.'
      redirect_to :action => 'show', :id => @gene
    else
      render :action => 'edit'
    end
  end

  def destroy
    Gene.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def sort_genes
    params[:genes].each_with_index do |id, index|
      Gene.update_all(['position=?', index+1], ['id=?', id])
    end
    render :nothing => true
  end

  def sort
    @genes = @proj.genes
  end

  # HMM- this weirdness can likely be removed
  def add_new
    gene = gene.new(params[:gene])
    gene.save || raise("Could not save gene.")
    
    renders_to_xml({
      :success => render_to_string(:partial => 'item', :collection => @proj.genes.find(:all)),
      :form => render_to_string(:partial => 'myform', :locals =>{:gene => Gene.new})
      })
    rescue
      renders_to_xml({:form => render_to_string(:partial => 'myform', :locals => {:gene => gene})})
   end

  def auto_complete_for_gene
    @tag_id_str = params[:tag_id]
    
    if @tag_id_str == nil
      redirect_to(:action => 'index', :controller => 'gene') and return
    else
       
      value = params[@tag_id_str.to_sym].split.join('%') # hmm... perhaps should make this order-independent
 
      lim = case params[@tag_id_str.to_sym].length
        when 1..2 then  10
        when 3..4 then  25
        else lim = false # no limits
      end 
      
      @genes = Gene.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id=?", "%#{value}%", value.gsub(/\%/, ""), @proj.id], :order => "name", :limit => lim )
    end
    
    render :inline => "<%= auto_complete_result_with_ids(@genes,
      'format_obj_for_auto_complete', @tag_id_str) %>"
  end

  
end
