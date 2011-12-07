class PrimersController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end

  def list # sorts by gene name!
    @primer_pages = Paginator.new self, @proj.primers.count, 30, params['page']
    @primers = Primer.find :all, :order => 'genes.position, genes.name',
                          :conditions => "(primers.proj_id = #{@proj.id})",
                          :limit  =>  @primer_pages.items_per_page,
                          :offset =>  @primer_pages.current.offset,
                          :include => :gene
  end

  def show
    id = params[:id]
    id ||= params[:primer][:id]
    @primer = Primer.find(id)
  end

  def new
    @primer = Primer.new
  end

  def create
    @primer = Primer.new(params[:primer])
  
    if @primer.save
      flash[:notice] = 'Primer was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @primer = Primer.find(params[:id])
  end

  def update
    @primer = Primer.find(params[:id])
    if @primer.update_attributes(params[:primer])
      flash[:notice] = 'Primer was successfully updated.'
      redirect_to :action => 'list', :id => @primer
    else
      render :action => 'edit'
    end
  end

  def destroy
    Primer.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def show_by_gene
    @primers = Primer.find_all_by_gene_id_and_proj_id(params['gene']['id'], @proj.id)
    render :action => 'list'
  end

  def auto_complete_for_primer
    value = params[:term]
    if @tag_id_str == nil
      redirect_to(:action => 'index', :controller => 'primers') and return
    else
      val = value.split.join('%')
      lim = case value.length
        when 1..2 then  10
        when 3..4 then  25
        else lim = false # no limits
      end 
      
      @primers = Primer.find(:all, :conditions => ["(name LIKE ? or sequence like ? OR id = ?) AND proj_id=?", "%#{val}%",  "%#{val}%", val.gsub(/\%/, ""), @proj.id], :order => "name", :limit => lim )
    end
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @primers, :method => params[:method])
  end

  
  
end
