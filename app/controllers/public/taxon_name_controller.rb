class Public::TaxonNameController < Public::BaseController

  def search_taxon_names
  end

  def search_help
  end

  def index
   # search
   # render :action => 'search'
  end
  
  def search
    @taxon_name = TaxonName.new
  end

  def list_by_repository
    @r = Repository.find_by_id(params[:repository_id])
    (redirect_to :action => :index if !@r) and return
    @taxon_names_pages = Paginator.new self, TaxonName.find(:all,
                                                :conditions => "((" + @proj.public_tn_sql + ") AND (type_repository_id = #{@r.id}))").size,                  
                                                25, 
                                                params['page']
     
    @taxon_names = TaxonName.find(:all,
                                     :conditions => "((" + @proj.public_tn_sql + ") AND (type_repository_id = #{@r.id}))" , 
                                    :limit  =>  @taxon_names_pages.items_per_page,
                                    :offset =>  @taxon_names_pages.current.offset,
                                    :order => 'taxon_names.l')

    @head_text = "Taxonic names with types at #{@r.name} (#{@r.coden})."     
  end
  
  def list    
    genus = params['genus'] || ""
    species = params['species'] || ""
    author = params['author'] || ""
    other = params['other'] || ""
    
    #  @proj.search_taxa(genus, species, author, other)
    
    if genus != ""
      @taxon_names_pages, @taxon_names = paginate :taxon_name, 
     :include => 'type_geog', 
         :join => TaxonName.clean(["LEFT JOIN (SELECT id as genus_id, l, r from taxon_names WHERE name LIKE ? AND iczn_group = 'genus') AS g 
           ON taxon_names.l > g.l AND taxon_names.r < g.r", "#{genus}%"]),
         :conditions => [ "((taxon_names.name LIKE ?) AND (author LIKE ?) AND (type_locality LIKE ?  OR geogs.name LIKE ?)  AND (#{@proj.public_tn_sql('taxon_names')}) AND (genus_id IS NOT NULL))",
          "#{species}%", "#{author}%", "%#{other}%" , "%#{other}%"  ], 
         :order_by => 'taxon_names.l', 
         :per_page => 30
    else
      @taxon_names_pages, @taxon_names = paginate :taxon_name, 
      :include => 'type_geog',
        :conditions => [ "((taxon_names.name LIKE ?) AND (author LIKE ?) AND (type_locality LIKE ? OR geogs.name LIKE ?)  AND (#{@proj.public_tn_sql}))",
         "#{species}%", "#{author}%", "%#{other}%", "%#{other}%"  ], 
        :order_by => 'taxon_names.l', 
        :per_page => 30
    end  
    render :layout => false
  end
   
  def browse
    if params[:genus]
      @family = params[:family]
      @letter = params[:letter]
      @genus = params[:genus]
      @taxon_names = @proj.public_species(@genus)
      render :action => 'species'
    elsif params[:letter]
      @family = params[:family]
      @letter = params[:letter]
      if @letter == "all"
        @genera = @proj.public_genera(@family)
      else
        @genera = @proj.public_genera(@family, @letter)
      end
      render :action => 'genera'
    elsif params[:family]
      @family = params[:family]
      @letters = @proj.public_letters(@family)
      # don't bother displaying the grouped genera if there aren't very many
      if @letters.size < 20
        @letter = "all"
        @genera = @proj.public_genera(@family)
        render :action => 'genera'
      else  
        render :action => 'letters'
      end
    else
      @families = @proj.public_families
    end
  end
  
  def show
    id = params[:id]
    id ||= params[:taxon_name][:id]

    if !id.nil? and @taxon_name = TaxonName.find(:first, :conditions => ["id = ?",id])
      @taxon_hists = @taxon_name.taxon_hists
    else
      flash[:notice] = "can't find that taxon name!"
      redirect_to :action => 'index'
    end
  end

  def auto_complete_for_taxon_name
    value = params[:term]
    method = params[:method]
    if value.nil? 
      redirect_to(:action => 'index', :controller => 'taxon_name') and return
    else 
      val = value.split.join('%') 
      lim = case params[tag_id_str.to_sym].length
            when 1..2 then 3 
            when 3..4 then 5 
            else lim = false 
            end 
      @taxon_names  = TaxonName.find(:all, :conditions => ["(name LIKE ? OR id = ?)", "%#{value}%", value], :order => "length(name), name", :limit => lim )
      render :json => Json::format_for_autocomplete_with_display_name(:entries => @taxon_names, :method => params[:method])
    end
  end



end

