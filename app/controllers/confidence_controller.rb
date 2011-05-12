class ConfidenceController < ApplicationController
  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }
    
  def index
    list
    render :action => 'list'
  end

  def list
    @confidences = @proj.confidences
  end

  def new
    @confidence = Confidence.new
    @confidence.html_color = 'BBBBEE'  # a default
  end

  def create
    @confidence = Confidence.new( params['confidence'])
    if @confidence.save
      flash[:notice] = 'Confidence was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @confidence = Confidence.find(params[:id])
  end

  def show
    id = params[:confidence][:id] if params[:confidence]
    id ||= params[:id]
    @confidence = Confidence.find(id)
  end

  def update
    @confidence = Confidence.find(params[:id])
    if @confidence.update_attributes(params[:confidence])
      flash[:notice] = 'Confidence was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    Confidence.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def merge
    if params[:merge_with][:id].blank? 
      flash[:notice] = 'Select a confidence.'
      redirect_to :action => :show, :id => params[:id] and return
    end
      msg = Confidence.find(params[:id]).merge_with(Confidence.find(params[:merge_with][:id]))
    flash[:notice] = msg                                                              
    redirect_to :action => 'list'
  end

  def sort_confidences
    params[:confidences].each_with_index do |id, index|
      Confidence.update_all(['position=?', index+1], ['id=?', id])
    end
    render :nothing => true
  end

  def popup
    @obj = ActiveRecord::const_get(params[:confidence_obj_class]).find(params[:confidence_obj_id]) # creates variable objects

    # works
    respond_to do |format|
		  format.html {} # default .rhtml
	    format.js { 
        render :update do |page|
          page.visual_effect :fade, "cl_#{@obj.class.to_s}_#{@obj.id}"
          page.insert_html :bottom, "c_#{@obj.class.to_s}_#{@obj.id}", :partial => 'popup', :locals => {:confidences => @proj.confidences.by_namespace(@obj.class), :obj => @obj}
        end
      }
		end
  end

  def apply_from_popup
   @obj = ActiveRecord::const_get(params[:obj_class]).find(params[:obj_id]) 
   @obj.update_attributes(:confidence_id => (params[:confidence][:id] == '-1' ? nil : params[:confidence][:id] ))
   render :update do |page|
      page.visual_effect :appear, "cl_#{@obj.class.to_s}_#{@obj.id}" # unhide the link
      page.replace "c_#{@obj.class}_#{@obj.id}", :partial => 'confidence/confidence_link', :locals => {:confidence_obj_id => @obj.id, :confidence_obj_class => @obj.class.to_s, :obj => @obj, :msg => ''  } 
      page.visual_effect :fade, "cp_#{@obj.class.to_s}_#{@obj.id}"  
      page.delay(2) do # need a delay so top effect works?
        page.remove "cp_#{@obj.class.to_s}_#{@obj.id}"  # and get rid of the popup
      end 
    end
  end

  # TODO: this should be straight javascript, not AJAX
  def cancel_from_popup
    # we need to return the parameters of the object back to the link for subsequent use (note- not the same as create_from_popup)!
    @obj = ActiveRecord::const_get(params[:confidence_o_class]).find(params[:confidence_o_id]) # creates variable objects

    render :update do |page|
      page.visual_effect :appear, "cl_#{@obj.class.to_s}_#{@obj.id}" # unhide the link
      page.visual_effect :fade, "cp_#{@obj.class.to_s}_#{@obj.id}"  
      page.delay(3) do # need a delay so top effect works?
        page.remove "cp_#{@obj.class.to_s}_#{@obj.id}"  # and get rid of the popup
      end 
    end
     #  render :layout => false, :partial => "tag_link", :locals => { :tag_obj_id => params[:tag_o_id], :tag_obj_class => params[:tag_o_class]}
  end

  def auto_complete_for_confidence
    @tag_id_str = params[:tag_id]
    
    if @tag_id_str == nil
      redirect_to(:action => 'index', :controller => 'confidence') and return
    else
       
      value = params[@tag_id_str.to_sym].split.join('%') # hmm... perhaps should make this order-independent
 
      lim = case params[@tag_id_str.to_sym].length
        when 1..2 then  10
        when 3..4 then  25
        else lim = false # no limits
      end 
      
      @confidences = Confidence.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id=?", "%#{value}%", value.gsub(/\%/, ""), @proj.id], :order => "name", :limit => lim )
    end
    
    render :inline => "<%= auto_complete_result_with_ids(@confidences,
      'format_obj_for_auto_complete', @tag_id_str) %>"
  end

  
end
