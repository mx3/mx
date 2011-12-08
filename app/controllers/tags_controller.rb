class TagsController < ApplicationController
  in_place_edit_for :tag, :notes

  def in_place_notes_update
    t = Tag.find(params[:id])
    t.update_attributes(:notes => params[:value])
    render :text => t.notes
  end

  def index
    list
    render :action => 'list'
  end

  def list
    @tags = Tag.by_proj(@proj).page(params[:page]).per(20).order('keyword_id, Created_on DESC, Updated_on DESC').includes(:keywords)
  end

  def list_by_keyword
    @keyword = Keyword.find(params[:keyword][:id])
    @tags = @keyword.tags.group_by {|o| o.addressable_type}
  end

  def show
    id = params[:keyword][:id] if params[:keyword]
    id ||= params[:id]
    @tag = Tag.find(id, :include => :metatags)
    @keyword = @tag.keyword
    @no_right_col = true
    @show = ['default']
  end

  def new
    @tag = Tag.new
    @obj = ActiveRecord::const_get(params[:tag_obj_class]).find(params[:tag_obj_id])
    @keyword_id = params[:keyword_id]
  end

  def create
    @tag = Tag.new(params[:tag])
    @obj = ActiveRecord::const_get(params[:tag_obj][:obj_class]).find(params[:tag_obj][:obj_id])
    @tag.addressable = @obj

    @html_selector = params[:html_selector]

    if @tag.save
      respond_to do |wants|
        wants.js { }
        wants.html { redirect_to :action => 'list' }
      end
      notice "Tagged #{@obj.class.name} ##{@obj.id}"
    else # didn't save the tag
      render :action=>"new"
    end
  end

  def edit
    @tag = Tag.find(params[:id])
    @obj = @tag.addressable
    @keyword = @tag.keyword
  end

  ## needs to be fixed
  def update
    @tag = Tag.find(params[:id])
    @obj = @tag.addressable

    if @tag.update_attributes(params[:tag])
      notice 'Tag was successfully updated.'
    else
      render :action => 'edit'
    end
  end

  def destroy
    @tag = Tag.find(params[:id])

    # need some references to update things with
    addressable_id = @tag.addressable_id
    addressable_type = @tag.addressable_type
    keyword_id = @tag.keyword.id

    if @tag.destroy
      notice 'Tag was successfully deleted.'
      respond_to do |format|
        format.html {
          redirect_to :action => :list and return
        }
        format.js { }
      end
    else
      notice 'Something wrong with tag deletion.'
      redirect_to :back  and return
    end
  end

  def _popup_info
    @tags = Tag.find(:all, :conditions => ["addressable_type = ? AND addressable_id = ? AND keyword_id = ? ", params[:addressable_type], params[:addressable_id].to_i, params[:keyword_id].to_i],  :include => [:ref, :keyword])
    @keyword = Keyword.find(params[:keyword_id])
    respond_to do |format|
      format.js {
        render :update do |page|
        # page.visual_effect :fade, "tl_#{@obj.class.to_s}_#{@obj.id}"
        page.insert_html :bottom, "cld_wrd_id_#{params[:keyword_id]}_#{params[:addressable_type]}_#{params[:addressable_id]}", :partial => 'popup_info', :locals => {:addressable_type => params[:addressable_type] , :addressable_id => params[:addressable_id]  }
        end
      }
    end
  end
end
