class TagController < ApplicationController
  in_place_edit_for :tag, :notes

  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }
          
  def in_place_notes_update
    t = Tag.find(params[:id])
    t.update_attributes(:notes => params[:value])
    render :text => t.notes
  end

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [  :create, :update, :destroy ], # removed :destroy,
         :redirect_to => { :action => :list }

  def list
    @keyword = Keyword.new
     
    page_params = {:per_page => 20, :order_by => 'keyword_id', :conditions => "(proj_id = #{@proj.id})"}
    params[:keyword_id] ? id = params[:keyword_id] : (params[:keyword] ? id = params[:keyword][:id] : id = false) 

    if id
      page_params[:conditions] = ['((keyword_id = ?) AND (proj_id = ?))', id, @proj.id]
    else    
      page_params[:conditions] = ['(proj_id = ?)', @proj.id]
    end
      
    page_params[:order_by] = 'Created_on DESC, Updated_on DESC'
   
    @keyword_id = id
    @tag_pages, @tags = paginate(:tags, page_params)

    if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
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
    session['tag_view']  = 'show'
    @show = ['show_default'] 
  end

  def new
    @tag = Tag.new
    @obj = ActiveRecord::const_get(params[:tag_obj_class]).find(params[:tag_obj_id]) # creates variable objects
    
    # works
    respond_to do |format|
		  format.html {} # default .rhtml
	    format.js { 
          render :update do |page|
            page.visual_effect :fade, "tl_#{@obj.class.to_s}_#{@obj.id}"
            page.insert_html :bottom, "t_#{@obj.class.to_s}_#{@obj.id}", :partial => 'popup_form', :locals => {:keyword_id => params[:keyword_id]}
          end
      }
		end
  end

  def create 
    @tag = Tag.new(params[:tag])   
    @obj = ActiveRecord::const_get(params[:tag_obj][:obj_class]).find(params[:tag_obj][:obj_id]) 
    @tag.addressable = @obj
    if @tag.save
      render :update do |page|
        page.remove "tp_#{@obj.class.to_s}_#{@obj.id}" # get rid of the form (use an effect)
        page.insert_html :top, "t_#{@obj.class.to_s}_#{@obj.id}", '<span id="quick_msg">Tagged!</span>' # provide msg to user        
        page.visual_effect :highlight, "quick_msg", :duration => 1 # make sure they see it
       
        page.delay(1) do # wait a bit and fade it out
          page.visual_effect :fade, "quick_msg" 
        end
        
        page.delay(2) do # and get rid of it completely so as to not confuse things down the road
          page.remove "quick_msg"                            
        end
        
        page.delay(3) do
             page.visual_effect :appear, "tl_#{@obj.class.to_s}_#{@obj.id}" # unhide the previously hidden Tag link
        end

        # javascript ifs are ugly, but relatively straightforward
        page << "if($('new_tags_wo_kw')) {"   # have an accordion on the page?
          page.visual_effect :appear, "new_tags_wo_kw"
          page.insert_html :bottom, "new_tags_wo_kw", (@tag.display_name(:type => :without_keyword, :close => false) + " " + destroy_tag_link(@tag)  + '</div>')
        page << "}"
            
        obj_txt = "_#{@tag.addressable_type}_#{@tag.addressable_id}"
        
        page << "if($('tag_cloud#{obj_txt}')) {" # have a tag cloud for that object on the page? 
          # remove blue sky if its there
          page << "if($('blue_sky#{obj_txt}')) {" # remove the first instance if it's there
            page.remove "blue_sky#{obj_txt}" 
          page << "}"

          page << "if($('cld_wrd_id_#{@tag.keyword.id}_#{@tag.addressable_type}_#{@tag.addressable_id}')) {" # remove the first instance if it's there
            page.remove "cld_wrd_id_#{@tag.keyword.id}_#{@tag.addressable_type}_#{@tag.addressable_id}" 
          page << "}"
        
          page.insert_html :bottom, "tag_cloud#{obj_txt}", tag_cloud_for(@obj, @tag.keyword.id, 'info') # add the new tag
        page << "}"
      
          page << "if($('meta_#{@tag.addressable_id}')) {" # insert into the string 
            page.replace_html "meta_#{@tag.addressable_id}", render(:partial => 'tag/tn', :object => @tag, :locals => {:level => 1, :newly_inserted => true})
          page << "}"
      end

        return
    else # didn't save the tag 
      render :update do |page|
         page.visual_effect :shake, "tp_#{@obj.class.to_s}_#{@obj.id}" # reset the form as well
         page.alert "That tag has already been created, or there was a problem creating it."
         page["tpf_#{@obj.class.to_s}_#{@obj.id}"].reset
      end
      return
    end 
  
    # this far? bad
    flash[:notice] = 'Problem with adding tag!'
    redirect_to :action => 'list'
  end

  # TODO: this should be straight javascript, not AJAX
  def cancel_from_popup
    # we need to return the parameters of the object back to the link for subsequent use (note- not the same as create_from_popup)!
    @obj = ActiveRecord::const_get(params[:tag_o_class]).find(params[:tag_o_id]) # creates variable objects
    render :update do |page|
      page.visual_effect :appear, "tl_#{@obj.class.to_s}_#{@obj.id}" # unhide the link
      page.visual_effect :fade, "tp_#{@obj.class.to_s}_#{@obj.id}"  
      page.delay(3) do # need a delay so top effect works?
        page.remove "tp_#{@obj.class.to_s}_#{@obj.id}"  # and get rid of the popup
      end 
    end
  end

  def edit
    @tag = Tag.find(params[:id])
    @keyword = @tag.keyword
  end

  ## needs to be fixed 
  def update
    @tag = Tag.find(params[:id])

    if @tag.update_attributes(params[:tag])
      flash[:notice] = 'Tag was successfully updated.'
      redirect_to :action => 'show', :id => @tag
    else
      render :action => 'edit'
    end
  end

  def destroy
    t = Tag.find(params[:id])

    # need some references to update things with
    addressable_id = t.addressable_id
    addressable_type = t.addressable_type
    keyword_id = t.keyword.id
    
    if t.destroy
 
    respond_to do |format|
		  format.html {
        flash[:notice] = 'Tag was successfully deleted.'
        redirect_to :action => :list and return
      } 
	    format.js { 
          render :update do |page|
            
            # remove tag from the info_popup if its up
            page << "if($('popup_info_tbl_#{params[:id]}')) {" # remove the first instance if it's there
              page.remove "popup_info_tbl_#{params[:id]}"
            page << "}"

            # remove tag if it's a list view 
            page << "if($('tag_#{params[:id]}')) {" 
              page.remove "tag_#{params[:id]}"
            page << "}"

            # if there are no tags on this object of this keyword type close some things
            if  Tag.find(:all, :conditions => ["addressable_type = ? AND addressable_id = ? AND keyword_id = ? ", addressable_type, addressable_id, keyword_id]).size == 0
              
              # remove the word from the cloud if it exists
              page << "if($('cld_wrd_id_#{keyword_id}_#{addressable_type}_#{addressable_id}')) {" 
                page.remove "cld_wrd_id_#{keyword_id}_#{addressable_type}_#{addressable_id}" 
              page << "}"

              # close the info popup
              page.remove "ti_#{addressable_type}_#{addressable_id}"
            end
            
            page.visual_effect :fade, "t_#{params[:id]}"
            
            page.delay(2) do
              page.remove "t_#{params[:id]}"
            end
          end
      }
		end

    else
      flash[:notice] = 'Something wrong with tag deletion.'
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

  def _close_popup_info
     # only called with .js

     respond_to do |format|
	      format.js { 
          render :update do |page|
            page.remove "ti_#{params[:addressable_type]}_#{params[:addressable_id]}"
            
            # tags in clouds are dealt with in # destroy
          end
      }
    end

  end
    
end
