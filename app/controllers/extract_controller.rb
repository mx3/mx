class ExtractController < ApplicationController

  # these must have corresponding partials of the same name
  REPORT_SUMMARY_TYPES = [:extracts_by_gene_colored, :extracts_by_gene_simple]

  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }
    
  def index
    list
    render :action => 'list'
  end

  def list_params
    @extract_pages, @extracts = paginate :extract, :per_page => 25, :conditions => "(proj_id = #{@proj.id})"
  end

  def list
    list_params
     if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def show
    @extract = Extract.find(params[:id])
  end

  def new
    @extract = Extract.new((params[:specimen_id].blank? ? {} : {:specimen_id => params[:specimen_id]}))
  end

  def create
   @extract = Extract.new(params[:extract])
  
    if @extract.save
      flash[:notice] = 'Extract was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @extract = Extract.find(params[:id])
  end

  def update 
    @extract = Extract.find(params[:id])

    if @extract.update_attributes(params[:extract])
      flash[:notice] = 'Extract was successfully updated.'
      redirect_to :action => 'show', :id => @extract
    else
      render :action => 'list'
    end
  end

  def summarize

    if request.post? 
      search = Extract.summarize_by(params[:search].merge(:proj_id => @proj.id))
      @genes = search[:genes]
      @extracts = search[:extracts]
    end

    respond_to do |format|
      format.html {
        if request.post? 
          if @extracts.size == 0 || @genes.size == 0
            flash[:notice] = "No genes or extracts returned, try another search"
            render :action => :summarize and return
          end

          case params[:report_type].to_sym
          when :extracts_by_gene_colored
            flash[:notice] = '<strong style="color:red;">That report not available as a file.</strong>'
            render :action => :summarize and return 

          when :extracts_by_gene_simple
            f = render_to_string(:partial => "extract/reports/#{params[:report_type].to_s}", :locals => {:genes => @genes, :extracts => @extracts}, :layout => false)
            send_data(f, :filename => 'mx_extract_summary.tab', :type => "application/rtf", :disposition => "attachment")
          end and return
        end 
      }

      format.js {
        if @extracts.size == 0 || @genes.size == 0
          render :update do |page|
            page.replace_html :result, :text => '<em style="color: red;">No results returned.</em>'
          end and return
        end 

      render :update do |page|
        page.replace_html :result, :partial => "extract/#{params[:report_type].to_s}", :locals => {:genes => @genes, :extracts => @extracts}
      end and return

      # something went horribly wrong, 
      #render :update do |page|
      #  page.replace_html :result, :text => '<strong>Controller misconfigured, contact admin.</strong>'
      # end and return
      }
    end

  end

  def destroy
    Extract.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def tag_by_range
    if request.post?
      if @keyword = Keyword.find(params[:tag_many][:keyword_id])

        begin
          Tag.transaction do 
            ArrayHelper.range_as_array(params[:tag_many][:extract_range]).each do |i|
              if e = Extract.find_by_id_and_proj_id(i, @proj.id)
                t = Tag.create_new(:obj => e, :keyword => @keyword)
                t.save!
              end
            end
          end

        rescue
          flash[:notice] = "You tried to tag something that is already tagged with that keyword."
          render :action => :tag_by_range and return
        end

        flash[:notice] = 'Success!'

      else
        flash[:notice] = 'No keyword chosen.'
        render :action => :tag_by_range and return
      end
    end
  end
 
  def auto_complete_for_extract
    value = params[:term]
    @extracts = Extract.find_for_auto_complete(value)
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @extracts, :method => params[:method])
  end

end
