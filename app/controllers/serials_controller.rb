class SerialsController < ApplicationController
  
  def index
    list
    render :action => 'list'
  end

  def list
    page_params = {:per_page => 30, :order_by => 'name'}
    if params[:search]
      value = params[:search].split.join('%')
      page_params[:conditions] = ['name like ?', "%#{value}%"]
      page_params[:per_page] = 99999 # all of them
    end
    
    @serial_pages, @serials = paginate(:serial, page_params)
    @paginate = true
   
    if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def show
    _show_params # TODO: before filter
    @show = ['default'] 
  end

  def show_all_refs
    _show_params
    @no_right_col = true 
    render :action => :show
  end

  def new
    @serial = Serial.new
  end

  def create
    @serial = Serial.new(params[:serial])
    if @serial.save
      flash[:notice] = 'Serial was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @serial = Serial.find(params[:id])
  end

  def update
    @serial = Serial.find(params[:id])
    if @serial.update_attributes(params[:serial])
      flash[:notice] = 'Serial was successfully updated.'
      redirect_to :action => 'show', :id => @serial
    else
      render :action => 'edit'
    end
  end

  def destroy
    begin
      Serial.find(params[:id]).destroy
      flash[:notice] = "Serial destroyed."
      redirect_to :action => 'list'
    rescue
      flash[:notice] = "Can't destroy serial, you likely have references attached to it."
      redirect_to :action => :show, :id => params[:id]
    end  
  end
  
  def match
    if request.post?
      if params[:temp_file].blank?
       flash[:notice] = "Choose a text file!"
      else          
        @file_serials = params[:temp_file].read.split(/\n/m).map {|x| x.strip}
      end
    end
  end

  def find_many
  end

  def auto_complete_for_serial
    value = params[:term]
    val = value.split.join('%') # hmm... perhaps should make this order-independent
    @serials = Serial.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND synonymous_with_id is NULL", "%#{val}%", val],
        :limit => 20, :order => "name")
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @serials, :method => params[:method])
  end

  def _add_ref_to_proj
    r = Ref.find(params[:ref_id])
    @proj.refs << r
    render :update do |page|
      page.replace_html "srid_#{r.id}", :text => "<div class=\"passed\" style=\"padding: 2px; margin: 2px;\">#{link_to(r.display_name, :controller => :refs, :action => :edit, :id => r)} [#{r.id}]</div>"
    end and return
  end

  def _download_biostor
   @serial = Serial.find(params[:id])
   @foo = @serial.biostor_table
   send_data @foo, :type => "text/plain", :filename=> "#{@serial.name.gsub(/\s/,"_")}.csv", :disposition => 'attachment' and return
  end

  protected
  def _show_params
    id = params[:serial][:id] if params[:serial]
    id ||= params[:id]
    @serial = Serial.find(id, :include => :refs)
  end 

end
