class Public::PublicContentsController < Public::BaseController

  def index
    list
    render :action => 'list'
  end

  def list
    @otus = @proj.otus.with_published_content
    @display_data = ByTnDisplay.new(nil, @otus)
  end

  def show
    @otu = Otu.find(params[:id], :include => [:contents, :content_types])
  
    begin  
    if @otu && @otu.contents.that_are_published.count > 0
      @content_template = ContentTemplate.template_to_use(params[:content_template_id], @proj.id)

      if @content_template.nil?
        flash[:notice] = "You haven't set a default template for this project. Adjust your settings."

        redirect_to :back and return  # necssary because we he this from other controllers
      end
      @page_content = @content_template.content_by_otu(@otu, true) 
    else
      flash[:notice] = "The information for the previously selected OTU has not yet been made available."
      redirect_to :back and return  # necssary because we he this from other controllers
    end
    # if we can't hit :back we rescue
    rescue ActionController::RedirectBackError
      redirect_to :action => :index, :controller => @proj.home_controller and return
    end
  end

  def _markup_description
    respond_to do |format|
      format.html {redirect_to :action => :list and return} # shouldn't be hit
      format.js {
        render :update do |page|
          if @o = Content.find(params[:id]) # there is always text otherwise header wont' be shown
            @l = Linker.new(:link_url_base => self.request.host, :proj_id => @proj.ontology_id_to_use, :is_public => true, :incoming_text => @o.text, :adjacent_words_to_fuse => 5)
            page.replace_html "content_#{params[:id]}", :text => RedCloth.new(@l.linked_text(:exclude_blank_descriptions => true)).to_html # htmlize from application_helper not available here
          else
            flash[:notice] = "Something went wrong when trying to markup a definition."
            render :action => 'index'
          end
        end
      }
    end
  end

  def show_kml_text
    @otu = Otu.find(params[:id])
    render :layout => false, :template => '/otu/show_kml_text'
  end

end
