class KeywordController < ApplicationController
   verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  before_filter :_show_params, :only => [:show, :show_tags]

  def index
    list
    render :action => 'list'
  end

  def list_params
    @keyword_pages, @keywords = paginate :keyword, :per_page => 30, :conditions => "(proj_id = #{@proj.id})", :order => "keyword"
  end

  def list
      list_params
     if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def _show_params
    id = params[:keyword][:id] if params[:keyword]
    id ||= params[:id]
    @keyword = Keyword.find(id)
  end

  def show
    @show = ['default']
    render :action => 'show'
  end

  def show_tags
    @tags = @keyword.tags.group_by{|o| o.addressable_type}
    @no_right_col = true
    render :action => 'show'
  end

  def new
    @keyword = Keyword.new
  end

  def create
    @keyword = Keyword.new(params[:keyword])

    if @keyword.save
      flash[:notice] = 'Keyword was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @keyword = Keyword.find(params[:id])
  end

  def update
    @keyword = Keyword.find(params[:id])
    if @keyword.update_attributes(params[:keyword])
      flash[:notice] = 'Keyword was successfully updated.'
      redirect_to :action => 'show', :id => @keyword
    else
      render :action => 'edit'
    end
  end

  def destroy
    Keyword.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def auto_complete_for_keyword

    @tag_id_str = params[:tag_id]
    value = params[:term]
    #value = params[@tag_id_str.to_sym].split.join('%')

    @keywords = Keyword.find(:all, :conditions => ["(keyword LIKE ? OR shortform LIKE ? OR id = ?) AND proj_id=?", "#{value}%", "#{value}%", value.gsub(/\%/, ""), @proj.id],        :limit => 20, :order => "keyword")

    data = @keywords.collect do |kw|
      {:id=> kw.id,
       :label=> kw.keyword,
       :response_values=> {
          'keyword[id]' => kw.id,
          :hidden_field_class_name => @tag_id_str
       },
       :label_html => kw.display_name(:type => :for_select_list) # format_obj_for_auto_complete(ref) # see include App::AutocompleteHelper above # render_to_string(:partial=>'shared/autocomplete/ref.html', :locals=>{:item=>ref})
      }
    end
    render :json => data
  end

end
