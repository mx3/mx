class DataSourceController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @data_source_pages, @data_sources = paginate :data_sources, :per_page => 20, :conditions => {:proj_id => @proj.id}
  end

  def show 
    @data_source = DataSource.find(params[:id])
    @show = ['default'] 
  end

  def show_file_contents
    @data_source = DataSource.find(params[:id])
    @no_right_col = true
    render :action => :show
  end

  # TODO: Logic to model
  def show_convert
    @data_source = DataSource.find(params[:id])
    @no_right_col = true

    if !@data_source.dataset
      flash[:notice] = "You need to attach a file to before you can convert this data source."
      redirect_to :action => :list and return
    end

    if request.post?
      # convert!! 
      options = {}
      options.update(:title => params[:title]) if !params[:title].blank?
      options.update(:generate_short_chr_name => true) if !params[:generate_short_chr_name].blank?

      options.update(:generate_otu_name_with_ds_id => @data_source.id) if !params[:generate_otu_name_with_ds_id].blank?
      options.update(:generate_chr_name_with_ds_id => @data_source.id) if !params[:generate_chr_name_with_ds_id].blank?

      # only gets turned on in form if ref is available, but maybe rest...
      if @data_source.ref
        options.update(:generate_chr_with_ds_ref_id => @data_source.ref.id) if !params[:generate_chr_with_ds_ref_id].blank?
        options.update(:generate_otu_with_ds_ref_id => @data_source.ref.id) if !params[:generate_otu_with_ds_ref_id].blank?
      end

      options.update(:match_otu_to_db_using_name => true) if !params[:match_otu_to_db_using_name].blank?
      options.update(:match_otu_to_db_using_matrix_name => true) if !params[:match_otu_to_db_using_matrix_name].blank?
      options.update(:match_chr_to_db_using_name => true) if !params[:match_chr_to_db_using_name].blank?

      begin
        @id =  @data_source.dataset.convert_nexus_to_db(options)
        flash[:notice] = "Converted!"
        redirect_to :action => :show, :controller => :mx, :id => @id and return
      rescue ParseError, ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
        flash[:notice] = "There was an error parsing the matrix: #{e}"
        redirect_to :action => :show_convert and return
      end
      
    else
      @form = true
      begin
        @nexus_file = @data_source.dataset.nexus_file
      rescue NexusParser::ParseError => e
        flash[:notice] = "error: #{e}"
      end
    end

    render :action => :show
  end

  def new
    @data_source = DataSource.new
  end

  def create
    @data_source = DataSource.new(params[:data_source])
    @dataset = Dataset.new(params[:dataset]) if !params[:dataset].blank? && !params[:dataset][:uploaded_data].blank?  
    
    begin 
      DataSource.transaction do
        if @dataset
          @dataset.save!
          @data_source.dataset = @dataset
        end
        @data_source.save!
        redirect_to :action => 'list'
      end
    rescue  ActiveRecord::RecordInvalid => e
      flash[:notice] = "There was a problem and the data source was not created. (#{e})"
      redirect_to :action => :new
    end
  end

  def edit
    @data_source = DataSource.find(params[:id])
  end

  def update
    @data_source = DataSource.find(params[:id])
    @dataset = Dataset.new(params[:dataset]) if not params[:dataset].blank? and not params[:dataset][:uploaded_data].blank?  
    
    begin 
      DataSource.transaction do
       @data_source.update_attributes(params[:data_source])

        if @dataset
          @dataset.save!
          @data_source.dataset = @dataset
        end
        @data_source.save!
        redirect_to :action => 'show', :id => @data_source
      end
    rescue  ActiveRecord::RecordInvalid
      flash[:notice] = "Somethign went wrong in the update, you may have uploaded an invalid file."
      render :action => 'edit'
    end
  end

  def destroy
    DataSource.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

   def _delete_dataset
     DataSource.find(params[:id]).dataset.destroy
     redirect_to :action => 'edit', :id => params[:id]
  end
  
  def auto_complete_for_data_source
      @tag_id_str = params[:tag_id]
      
      if @tag_id_str == nil
        redirect_to(:action => 'list', :controller => 'data_source') and return
      else
         
        value = params[@tag_id_str.to_sym].split.join('%') # hmm... perhaps should make this order-independent
     
        @data_sources = DataSource.find(:all, :include => [:dataset], :conditions => ["(name LIKE ? OR datasets.filename like ? or data_sources.id = ? ) AND data_sources.proj_id=?", "%#{value}%", "%#{value}%", value.gsub(/\%/, ""), @proj.id], :order => "name")
      end
      
      render :inline => "<%= auto_complete_result_with_ids(@data_sources,
        'format_obj_for_auto_complete', @tag_id_str) %>"
    end
end
