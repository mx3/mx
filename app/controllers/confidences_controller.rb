class ConfidencesController < ApplicationController

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
      notice 'Confidence was successfully created.'
      redirect_to :action => :show, :id => @confidence.id
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
      notice 'Confidence was successfully updated.'
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    Confidence.find(params[:id]).destroy
    notice "Confidence destroyed"
    redirect_to :action => 'list'
  end

  def merge
    if params[:merge_with] && params[:merge_with][:id]
      merge_source = Confidence.find(params[:id])
      merge_target = Confidence.find(params[:merge_with][:id])

      if (merge_source && merge_target)
        msg = merge_source.merge_with(merge_target)
        notice msg
      else
        error "Could not locate both merge source and merge target"
      end
      redirect_to :action => 'list'
    else
      notice 'Select a confidence.'
      redirect_to :action => :show, :id => params[:id] and return
    end
  end

  def sort
    params[:confidence].each_with_index do |id, index|
      Confidence.update_all(['position=?', index+1], ['id=?', id])
    end
    notice "Updated confidence order"
    head(200)
  end

  def popup
    @obj = ActiveRecord::const_get(params[:confidence_obj_class]).find(params[:confidence_obj_id]) # creates variable objects

    respond_to do |format|
      format.html {} # default .rhtml
      format.js { }
    end
  end

  def apply_from_popup
   @obj = ActiveRecord::const_get(params[:obj_class]).find(params[:obj_id])
   @obj.update_attributes(:confidence_id => (params[:confidence][:id] == '-1' ? nil : params[:confidence][:id] ))
  end

  def auto_complete_for_confidences
    value = params[:term].split.join('%')
    lim = case params[:term].length
          when 1..2 then  10
          when 3..4 then  25
          else lim = false # no limits
          end
    @confidences = Confidence.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id=?", "%#{value}%", value.gsub(/\%/, ""), @proj.id], :order => "name", :limit => lim )
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @confidences, :method => params[:method])
  end

end
