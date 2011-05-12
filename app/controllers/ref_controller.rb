class RefController < ApplicationController
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    list
    render :action => :list
  end
 
  def list
    list_params
     if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end

  def list_by_scope
    if params[:arg]
      @refs = @proj.refs.send(params[:scope],params[:arg]).ordered_by_cached_display_name
    else
      @refs = @proj.refs.send(params[:scope]).ordered_by_cached_display_name
    end 
    @list_title = "References #{params[:scope].humanize.downcase}" 
    render :action => :list_simple
  end

  def show 
    id = params[:ref][:id] if params[:ref] # for ajax picker use
    id ||= params[:id]
  
    if id.nil?
      flash[:notice] = $ERR_NO_ID
      redirect_to :action => 'list', :controller => 'ref' and return
    end
    
    if @ref = Ref.find(:first, :conditions => ["refs.id = ?", id], :include => [:serial, :taxon_names])
      session['ref_view']  = 'show'
       @show = ['show_default'] # not redundant with above- @show necessary for display of multiple of items 
    else
      flash[:notice] = "can't find that ref!"
      redirect_to :action => :list, :controller => :ref
    end
  end

  def new
    @ref = Ref.new
    1.times {@ref.authors.build}
    @target = 'new'
  end

  def create
    begin
      @ref = Ref.new(params[:ref])
      @ref.save! 
      if !params[:pdf].blank? && !params[:pdf][:uploaded_data].blank? &&  @pdf = Pdf.new(params[:pdf])
        Ref.transaction do
          if @pdf
            @pdf.save!
           @ref.pdf = @pdf
          end
          @ref.save

          if @identifier = Identifier.create_new(params[:identifier].merge(:object => @ref))
            @identifier.save!
          end

        end
      end
   
      @proj.refs << @ref  # make sure the ref is in this project as well
      flash[:notice] = 'Ref was successfully created.'
    rescue ActiveRecord::RecordInvalid => e
      flash[:notice] = "Ref was NOT created #{e.record.errors.collect{|e| e.join(" ").to_s}}. If you recieve a content_type error the pdf is not being recognized, see wiki-help."
      render :action => "new" and return 
    end
    
    redirect_to :action => :edit, :id => @ref.id
  end

  def edit
    if @ref = Ref.find(params[:id])
      @target = 'edit' 
    else
      redirect_to :action => 'list', :controller => 'ref' and return
      flash[:notice] = "Can't edit nothing."
    end
  end

  def _destroy_author
    author =  Author.find(params[:author_id])
    ref = Ref.find(author.ref_id)
    ref.authors.destroy(author)
    ref.save

    render :update do |page|
      page.replace_html :display_name, :text => ref.cached_display_name 
      page.remove "author_#{params[:author_id]}" 
    end and return
  end

  def sort_authors
    params[:authors].each_with_index do |id, index|
      Author.update_all(['position=?', index+1], ['id=?', id])
    end

    ref = Author.find(params[:authors].first).ref
    ref.save!

    render :update do |page|
      page.replace_html :display_name, :text => ref.cached_display_name 
    end and return
  end

  def delete_pdf
     Ref.find(params[:id]).pdf.destroy
     redirect_to :action => 'edit', :id => params[:id]
  end

  # TODO: too much logic here 
  def update
    @ref = Ref.find(params[:id])
    @target = 'update'
    
    old_ref = @ref.clone 
    old_authors = old_ref.authors.map{|a| a.clone }

    begin
      Ref.transaction do
        @ref.update_attributes(params[:ref]) 
        if @identifier = Identifier.create_new(params[:identifier].merge(:object => @ref))
          @identifier.save!
        end

        if !params[:pdf].blank? && !params[:pdf][:uploaded_data].blank? && (@pdf = Pdf.new(params[:pdf]))
          if @pdf
            if @pdf.save!
              @ref.pdf = @pdf
              @ref.save
            else
              flash[:notice] << "Could not save PDF. You might want to check the wiki-help."
            end
          end
        end
        @ref.notify_if_needed(old_ref, old_authors) # Sends email if there are changes that affect other projects      
        flash[:notice] = "Reference updated."
      end 

    rescue ActiveRecord::RecordInvalid => e 
      flash[:notice] = "Failed to update the record: #{e.message}."
      redirect_to :back and return
    end 

    if params[:update_and_next]
      redirect_to :action => :edit, :id => Ref.find(:first, :include => :projs, 
        :conditions => ["projs.id = #{@proj.id} AND refs.id > ?", @ref.id], :order => 'refs.id ASC')
    else
      redirect_to :action => :edit, :id => @ref
    end
 
  end
  
  def replace
    @ref = Ref.find(params[:id])
    if request.post? 
      
     if !params[:ref_from_another_proj].blank? && @replacement_ref = Ref.find(params[:ref_from_another_proj])
       @ref.delete_or_replace_with(@replacement_ref)    
     elsif !params[:replacement_ref][:id].blank? && @replacement_ref = Ref.find(params[:replacement_ref][:id])
       @ref.delete_or_replace_with(@replacement_ref)    
     else   
      flash[:notice] = "Couldn't find that reference!"
      redirect_to :action => :replace and return
     end 
      
      flash[:notice] = "Replaced all links to Ref #{@ref.id} with Ref #{@replacement_ref.id}"
      redirect_to :action => :show, :id => @replacement_ref.id and return
    end
  end

  def ocr_text
    @ref = Ref.find(params[:id])
  end

  def add
    if request.post?
      if params[:other_proj_id]
        other_proj = Proj.find(params[:other_proj_id])
        old_count = @proj.refs.size # refs is used below anyway, so this isn't a performance problem
        @proj.refs = (other_proj.refs + @proj.refs).uniq
        flash[:notice] = "Added #{@proj.refs.size - old_count} new references"
      elsif params[:ref_for_proj_add]
        ref = Ref.find(params[:ref_for_proj_add][:id])
        @proj.refs << ref unless @proj.refs.include?(ref)
        flash[:notice] = "Added one reference (#{ref.id})"
      end
    end
    @projects = Proj.find(:all) - [@proj]
  end
  
  def destroy
    if @r = Ref.find(params[:id])
      begin
        @r.delete_or_replace_with(nil)
        flash[:notice] = "Deleted the reference #{params[:id]}."
      rescue
        flash[:notice] = 'Something is wrong. Failed to delete that reference.'
        redirect_to :action => 'show', :id => @r and return
      end  
    end
    redirect_to :action => 'list'
  end
   
  def auto_complete_for_ref 
    @tag_id_str = params[:tag_id]
    value = params[@tag_id_str.to_sym].split.join('%')
   
    # TODO scope this  
    @refs = Ref.find(:all, :include => :projs, :select => "refs.id, refs.cached_display_name", 
      :conditions => ["(refs.cached_display_name LIKE ? OR refs.id = ?) AND projs.id = ?",
         "%#{value}%", value.gsub(/\%/, "").to_i, @proj],
      :limit => 20, :order => "refs.cached_display_name")
        
    render :inline => "<%= auto_complete_result_with_ids(@refs,
      'format_obj_for_auto_complete', @tag_id_str) %>"
  end
  
  # basically identical to above, used when finding refs to add from other projects
  def auto_complete_for_ref_other_projs
    @tag_id_str = params[:tag_id]
    value = params[@tag_id_str.to_sym].split.join('%')
    
    # TODO: move to Ref    
    # need to be tricky to exclude refs that are shared with other projects
    @refs = Ref.find_by_sql(["SELECT DISTINCT refs.id, refs.cached_display_name FROM refs 
    LEFT JOIN projs_refs ON projs_refs.ref_id = refs.id AND projs_refs.proj_id = ?
    WHERE projs_refs.ref_id IS NULL AND (refs.cached_display_name LIKE ? OR refs.id = ?)
    LIMIT 20", @proj.id, "%#{value}%", value.gsub(/\%/, "").to_i])
        
    render :inline => "<%= auto_complete_result_with_ids(@refs,
      'format_obj_for_auto_complete', @tag_id_str) %>"    
  end

  # TODO make this this admin
  def update_all_proj_display_names 
    @proj.update_all_refs
    flash[:notice] = 'Updated cached_display_name field for all refs in project'
    redirect_to :action => 'list'
  end

  def list_by_author
    @target = 'letter'                        
    if params['letter']
      @refs =  Ref.by_author_first_letter_and_proj_id(params['letter'], @proj.id)
    elsif params['name']
      @refs = @proj.refs.with_author_last_name(params[:name])
      @target = 'name'
    else
      @refs = []
    end
  end

  def show_tags
    @ref = Ref.find(params[:id], :include => [:serial, :taxon_names])
    
    @ref_tagged_through = @ref.through_tags.group_by {|t| t.addressable_type}
    @ref_tags = @ref.tags.group_by {|t| t.keyword}

    session['ref_view']  = 'show_tags'
     @show = ['show_tags'] 
    @no_right_col = true
    render :action => 'show'
  end
 
  def show_associations
    @ref = Ref.find(params[:id], :include => [:serial, :taxon_names])
    @associations = Association.by_ref(@proj.id, @ref.id)
    session['ref_view']  = 'show_associations'
     @show = ['show_associations'] 
    @no_right_col = true
    render :action => 'show'
  end

  def show_distributions
    @ref = Ref.find(params[:id])
    @distributions =  @ref.distributions.by_proj(@proj).ordered_by_geog_name
    session['ref_view']  = 'show_distributions'
    @show = ['show_distributions'] 
    @no_right_col = true
    render :action => 'show'
  end

  def show_sensus
    @ref = Ref.find(params[:id])
    @sensus = @ref.sensus.by_proj(@proj).ordered_by_label
    session['ref_view']  = 'show_sensus'
    @show = ['show_sensus'] 
    @no_right_col = true
    render :action => 'show'
  end

  def link_search
    @ref = Ref.find(params[:ref][:id]) if params[:ref] and params[:ref][:id]
    render(:layout => 'minimal') and return
  end

  def create_tags_for_all_parts
      @ref = Ref.find(params[:id])
      if @ref
        if count =  @ref.tag_all_parts(params[:tag].update('proj_id' => @proj.id))
          flash[:notice] = "Tagged #{count} terms."
        else
          flash[:notice] = "Tagged 0 terms. You may not have provided a keyword OR all terms already tagged with the given keyword."
        end
          redirect_to :action => :show_terms, :id => @ref.id
      else
        flash[:notice] = "Reference not found."
        redirect_to :action => :list
      end
  end
  
  def endnote
  end
 
  # only hit from an AJAX call now 
  def endnote_batch_verify_or_create
    if params[:incoming_endnote].blank?
     render :update do |page|
      page.replace_html :results, :txt => '<strong style="color:red;"> No text to parse </strong>'
     end and return
    end 

    @endnote_file = params[:incoming_endnote]
    md5 = Digest::MD5.hexdigest(@endnote_file)
      
    begin
      if params[:verify]
        if @results = Ref.new_from_endnote(:endtext => params[:incoming_endnote], :proj_id => @proj.id)
          session["#{$person_id}_end_ld_md5_#{md5}"] = md5 # nothing has been thrown, verify this text in the session
          render :update do |page|
            page.replace_html :endnote_form, :partial => 'endnote_form', :locals => {:txt => @endnote_file, :button => 'save'} 
            page.replace_html :result, :partial => 'endnote_batch_verify_result', :locals => {:results => @results, :operation => 'verifying', :endnote_file => @endnote_file} 
           end and return
        end
      elsif params[:save]
        if session["#{$person_id}_end_ld_md5_#{md5}"] == md5 # then this person verified this text 
          @results = Ref.new_from_endnote(:endtext => params[:incoming_endnote], :proj_id => @proj.id, :save => true)
          render :update do |page|
            page.replace_html :result, :partial => 'endnote_batch_verify_result', :locals => {:results => @results, :operation => 'saved!', :endnote_file => @endnote_file} 
          end and return 
        else # it's not verified
           render :update do |page|
            page.replace_html :result, :text => '<strong style="color:red;"> Data altered since verification, verify again. </strong>'
            page.replace_html :endnote_form, :partial => 'endnote_form', :locals => {:txt => @endnote_file, :button => 'verify'} 
           end and return 
        end
      end
    rescue Ref::RefBatchParseError => e
     render :update do |page|
      page.replace_html :result, :text => '<strong style="color:red;"> Error parsing the text. </strong>'
     end and return 
    end
    # if you got this far something went very wrong
  end

  def _count_labels
    @ref = Ref.find(params[:id])
    @ref.count_labels(@proj.id)
    @ref.reload
    render :update do |page|
      page.replace_html :term_usage, :partial => 'term_usage', :locals => {:labels_refs => @ref.labels_refs}
    end and return 
  end

  protected
  
  def list_params
    @ref_pages, @refs = paginate :ref, { :per_page => 20, :include => [:projs, :creator, :updator, :authors],
        :conditions => [ 'projs.id =?', @proj.id ], :order_by => 'cached_display_name'} # cached_display_name should have all this - author, year, full_citation
  end

end
