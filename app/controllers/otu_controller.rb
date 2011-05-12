class OtuController < ApplicationController
  
  verify :method => :post, :only => [ :destroy, :create, :update, :remove_from_otu_group],
         :redirect_to => { :action => :list }
 
  before_filter :show_params, :only => [:show, :show_summary, :show_map, :show_distribution, :show_tags_no_layout, :show_groups, :show_material_examined, :show_content, :show_matrix_sync, :show_compare_content, :show_all_content, :show_codings, :show_material, :show_molecular, :show_images, :show_tags, :show_matrices ]

  def index
    list
    render :action => 'list'
  end

  def list
    list_params
    if request.xml_http_request?
      render(:layout => false, :partial => 'ajax_list')
    end
  end
  
  def list_all
    @otu_pages = nil
    @otus = Otu.find(:all, :conditions => "(proj_id = #{@proj.id})")
    render :action => 'list'
  end

  def show 
    session['otu_view']  = 'show'
    @show = ['show_default'] 
  end

  def show_summary
    @klass = "Otu"
    session['otu_view'] = 'show_summary'
    @show = ['show_summary']
    render :action => 'show'
  end

  # TODO: KLM literal coming
  def show_kml_text
    @otu = Otu.find(params[:id])
    render :layout => false
  end

  # Specimen mapping (NOT distributions)
  def show_map
    @no_right_col = true 
    session['otu_view']  = 'show_map'
    @show = ['show_map']
    render :action => 'show'
  end

  def show_distribution
    @no_right_col = true 
    @distributions = @otu.distributions.ordered_by_geog_name
    session['otu_view']  = 'show_distribution'
    @show = ['show_distribution']
    render :action => 'show'
  end

  def show_tags_no_layout
    @tags = @otu.tags
    session['otu_view']  = 'show_tag_search_no_layout'
    @show = ['show_tag_search_no_layout']
    render :layout => false
  end

  def show_groups
    @otu_groups_in = @otu.otu_groups 
    @otu_groups_out = @proj.otu_groups - @otu_groups_in
    @no_right_col = true 
    session['otu_view']  = 'show_groups'
    @show = ['show_groups']
    render :action => 'show'
  end

  def show_material_examined
    session['otu_view']  = 'show_material_examined'
    @me = MaterialExamined.new(:otu_id => @otu.id)
    @no_right_col = true 
    @show = ['show_material_examined']
    render(:action => 'show')
  end

  def show_content
    redirect_to :action => :edit_page, :id => params[:id] 
  end

  def preview_public_page
    @otu = Otu.find(params[:id])
    @content_template = ContentTemplate.template_to_use(params[:content_template_id], @proj.id)

    if @content_template.nil?
      flash[:notice] = 'To visualize content for an OTU you must create a content template first.'
      redirect_to :action => :new, :controller => :content_template and return
    end 

    @public = true
    render :partial => 'content_template/page', :locals => {:content => @content_template.content_by_otu(@otu, true)}, :layout => 'otu_page_public_preview' 
  end

  def show_matrix_sync
    @content = @otu.text_content # a hash with content_type_id => Content
    session['otu_view']  = 'show_matrix_sync'
    @show = ['show_matrix_sync']
    render :action => 'show'
  end

  # TODO: needs some error catching 
  def update_content_from_matrix_sync
    @otu = Otu.find(params[:id])

    params[:ct].keys.each do |ct_id|
      txt = ContentType.find(ct_id).natural_language_by_otu(@otu)
      if @c = Content.by_otu(@otu).by_content_type(ct_id).first 
      else
        @c = Content.new(
          :otu_id => @otu.id,
          :content_type_id => ct_id,
          :license => @proj.default_license)
      end
      @c.text = txt
      @c.save
    end

    redirect_to :action => 'show_matrix_sync', :id => @otu
  end

  def _update_content_page
    # renders a template for show_content pages
    @otu = Otu.find(params[:otu_id])
    @content_template = ContentTemplate.find(:first, :conditions => "id = #{params.keys.sort[0].to_i} and proj_id = #{@proj.id}")

    render :update do |page|
      page.replace_html :contents, :partial => "content_template/page" , :locals => {:content => @content_template.content_by_otu(@otu, false)}
      page.replace_html :transfer_form, :partial => 'content/transfer_form'
      page.replace_html :content_options, :partial => 'content_template/page_header_and_options'
      flash.discard
    end and return    
  end

  # content comparison 
  def show_compare_content
    session['otu_view']  = 'show_compare_content'
    
    if params[:content_type_id].blank?
      @content_type = ContentType.find(:first, :conditions => "proj_id = #{@proj.id}")   
    else
      @content_type = ContentType.find(params[:content_type_id])
      @left_content = Content.find(:first, :conditions => "content_type_id = #{@content_type.id} and otu_id = #{@otu.id}") 
    end
    
    if !@content_type
      flash[:notice] = "Create a content type and template first."
      redirect_to :action => :index, :controller => :content_type and return 
    end
    
    @no_right_col = true 
    @show = ['show_compare_content']

    @left_lock = true
    @right_lock = false
    
    render(:action => 'show')
  end

  def show_all_content
    # TODO: this isn't really *all*, it's non published
    session['otu_view']  = 'show_all_content'
    @contents = @otu.contents.that_are_editable
    @no_right_col = true 
    @show = ['show_all_content']
    render(:action => 'show')
  end
  
  def _refresh_compare_content
    compare_params
    render(:layout => false, :partial => "content_type/compare", :locals => {:left_otu => @left_otu, :right_otu => @right_otu} ) 
  end
  
  def _update_compare_content
    compare_params
 
    if params[:left_content] and @left_content
      @left_content.text = params[:left_content] unless params[:left_content].empty?
      @left_content.save
    elsif params[:left_content] and not params[:left_content].blank?
      @c = Content.new(:otu_id => @left_otu.id, :content_type_id => @content_type.id, :text => params[:left_content], :license => @proj.default_license)
      @c.save
      @left_content = @c
    end
    
    if params[:right_content] and @right_content
      @right_content.text = params[:right_content] unless params[:right_content].empty?
      @right_content.save
    elsif params[:right_content] and not params[:right_content].blank?
      @c = Content.new(:otu_id => @right_otu.id, :content_type_id => @content_type.id, :text => params[:right_content], :license => @proj.default_license)
      @c.save
      @right_content = @c
    end
    
    # don't allow left and right to match
    
    render(:layout => false, :partial => "content_type/compare", :locals => {:left_otu => @left_otu, :right_otu => @right_otu} ) 
  
  end

  def show_codings
    session['otu_view']  = 'show_codings'
    @mxes = @otu.mxes
    @codings = []
    if params[:show_all] 
      @uniques = Coding.unique_for_otu(@otu)
      @codings = @otu.codings.ordered_by_chr
    end

    @no_right_col = true 
    @show = ['show_codings']
    render :action => 'show'
  end

  # merge with above
  def _update_codings
    # renders a template for show_content pages
    @otu = Otu.find(params[:id])

    @uniques = Coding.in_matrix(params[:mx][:id]).unique_for_otu(@otu)
    @codings = @otu.codings.in_matrix(params[:mx][:id]).ordered_by_chr

    render :update do |page|
      page.replace_html :codings, :partial => "otu/codings" 
      flash.discard
    end and return    
  end

  def show_material 
    session['otu_view'] = 'show_material'
    @specimens = Specimen.determined_as_otu(@otu).limit(500).include_identifiers.include_has_manys.include_tags # @otu.specimens_most_recently_determined_as(:limit => 10) # Specimen.find(:all, :conditions => "proj_id = #{@proj.id} and specimen_determinations.otu_id = #{@otu.id}", :include => 'specimen_determinations') #  
    @lots = @otu.lots.limit(500).include_has_manys.include_identifiers.include_tags # Lot.find(:all, :conditions => {:otu_id => @otu.id}, :include => [:identifiers, :ce, :repository], :limit => 100)
    @total_specimens = @otu.specimens.count
    @total_lots = @otu.lots.count
    @total_ipt_records = @otu.ipt_records.count 
    @no_right_col = true 
    @show = ['show_material']
    render :action => 'show'
  end

  def show_associations
    if @otu = Otu.find(params[:id], :include => [:creator, :updator, :taxon_name]) 
      session['otu_view']  = 'show_associations'
      @inc_actions = false # switch to false in public controller
      @no_right_col = true
      @show = ['show_associations']
      render :action => 'show'
    else
     flash[:notice] =  "can't find that OTU!"  
     redirect_to :action => 'list', :controller => 'otu'
   end
  end

  def show_molecular 
    @otus = ([@otu]) # a kludge so we can use the extract partial
    @seqs = @otu.sequences 
    @no_right_col = true
    session['otu_view']  = 'show_molecular'
    @show = ['show_molecular']
    render :action => 'show'
  end

  def show_images
    @images_from_image_descriptions = @otu.image_descriptions.by_proj(@proj.id)
    @images_from_codings = @otu.images_from_codings
    @images_from_specimens = @otu.images_from_specimens
    @no_right_col = true 
    session['otu_view']  = 'show_images'
    @show = ['show_images']
    render :action => 'show'
  end
 
  def move_images_to_otu
    if @o = Otu.find(params[:otu_id])  
      if  @o.move_images_to_otu(params[:o][:otu_to_find_id])
        flash[:notice] = 'Moved!'
      else
        flash[:notice] = 'Something went wrong with the transfer.'
      end
    end
      redirect_to :back
  end
  
  def show_tags
    @tags = @otu.tags.group_by {|keyword| keyword.keyword} # visibility isn't an issue if you've got this far
    
    @no_right_col = true 
    session['otu_view']  = 'show_tags'
    @show = ['show_tags']
    render :action => 'show'
  end
 
  def show_matrices
    @mxes = @otu.mxes
    session['otu_view']  = 'show_matrices'
    @show = ['show_matrices']
    
    render :action => :show
  end
  
  def new
    @otu = Otu.new
    @otu_groups = @proj.otu_groups
  end

  def create
    @otu_groups = @proj.otu_groups
    # Called to allow recursive addition of Otus from a TaxonName and its children 
    if id = Otu._create_r(:otu => params[:otu], :include_children => params[:include_children], :otu_group_id => params[:otu_group_id], :proj_id => @proj.id)
      flash[:notice] = (params[:include_children] ? 'OTUs were successfully created.' : 'OTU was successfully created')  
      redirect_to :action => :show, :id => id 
    else
      flash[:notice] = 'Problem creating the OTU(s)!' 
      render :action => :new and return
    end
    
  end

  def edit
    @otu = Otu.find(params[:id])
    @otu_groups = @proj.otu_groups
    render :action => 'edit'
  end

  def update
    @otu = Otu.find(params[:otu][:id])
    
    if @otu.update_attributes(params[:otu])
      flash[:notice] = 'Otu was successfully updated.'
       if params[:update_and_next]
        redirect_to :action => 'edit', :id => Otu.find(:first, :include => :proj, 
        :conditions => ["projs.id = #{@proj.id} AND otus.id > ?", @otu.id], :order => 'otus.id ASC')
       else
        redirect_to :action => 'show', :id => @otu.id
      end
    else
      render :action => 'edit'
    end
  end

  def destroy
    if @otu = Otu.find(params[:id])
      begin
       @otu.destroy 
       flash[:notice] =  "OTU deleted."         
       rescue StandardError => e
        flash[:notice] =  "OTU not deleted.  Perhaps you are using it somewhere. (#{e.message})"         
        redirect_to :action => :show, :id => @otu and return
      end  
    else
      flash[:notice] =  "Can't find that OTU!" 
    end 
    redirect_to :action => 'list'
  end
  
  def edit_page
    @otu = Otu.find(params[:id])
    @content_template = ContentTemplate.template_to_use(params[:content_template_id], @proj.id)
    @templates = @proj.content_templates - [@content_template]
    @editable_otu_contents = @otu.contents.that_are_editable
    @edit = true
  end
  
  def update_edit_page
    @otu = Otu.find(params[:otu_id])
    @content_template = ContentTemplate.find(params[:content_template_id])
    @templates = @proj.content_templates - [@content_template]

    respond_to do |format|
      format.html {
      }
      format.js {
        
        if !params[:content].nil? 

          if !@content_template.update_content(params.update(:otu => @otu, :contents => @otu.contents.that_are_editable))
            render :update do |page|
              page.replace :form_notice, :text => content_tag(:div, 'Error updating text, current version shown', :id => 'form_notice')
              page.visual_effect :fade, :form_notice
              page.replace_html :working, :partial => 'edit_page_content_form', :locals => {:otu => @otu, :content_template => @content_template}
            end and return
          end
        end

        case params[:view]

        when 'edit'
          @editable_otu_contents = @otu.contents.that_are_editable
          render :update do |page|
            if !params[:content].nil? 
              page.replace :form_notice, :text => content_tag(:div, 'Text saved.', :id => 'form_notice')
              page.visual_effect :fade, :form_notice
            end 

            page.replace_html :working, :partial => 'edit_page_content_form', :locals => {:otu => @otu, :content_template => @content_template}
          end and return

        when 'working'
          render :update do |page|
            page.replace :form_notice, :text => content_tag(:div, 'text saved', :id => 'form_notice')
            page.visual_effect :fade, :form_notice
            page.replace_html :working, :partial => "/content_template/page", :locals => {:content => @content_template.content_by_otu(@otu, false)}
          end and return

        when 'published'
          @public = true;
          render :update do |page|
            page.replace :form_notice, :text => content_tag(:div, 'text saved', :id => 'form_notice')
            page.visual_effect :fade, :form_notice
            page.replace_html :working, :partial => "/content_template/page", :locals => {:content => @content_template.content_by_otu(@otu, true)}
          end and return

        when 'publish'
          @content_template.publish(@otu)
          @editable_otu_contents = @otu.contents.that_are_editable
          render :update do |page|
            page.replace :form_notice, :text => content_tag(:div, 'Text saved and published..', :id => 'form_notice')
            page.visual_effect :fade, :form_notice
            page.replace_html :working, :partial => "/content_template/page", :locals => {:content => @content_template.content_by_otu(@otu, true)}
          end and return

        end        
      }
    end   
  
  end
  
  def auto_complete_for_otu
    @tag_id_str = params[:tag_id]
    value = params[@tag_id_str.to_sym]
        
    @otus = Otu.find_for_auto_complete(value)
    render :inline => "<%= auto_complete_result_with_ids(@otus,
      'format_obj_for_auto_complete', @tag_id_str) %>"
  end
  
  # redundancy with OTU group add - but nice fn()
  def add_to_otu_group
     if OtuGroup.find(params[:otu_group_id]).add_otu(Otu.find(params[:otu_hook][:id]))
        flash[:notice] = 'Added this OTU to a group.'
     else
        flash[:notice] = 'Error in adding OTU to group.'
     end    
    redirect_to :action => 'show_groups', :id => params[:otu_hook][:id]  
  end

  def remove_from_otu_group
    OtuGroup.find(params[:id]).remove_otu(Otu.find(params[:otu_id]))  
    redirect_to :action => 'show_groups', :id => params[:otu_id]
  end
 
# def publish_page
#   o = Otu.find(params[:id]) or raise 'failed to find Otu in publish_page'
#   t = ContentTemplate.find(params[:content_template_id])
#   
#   if t.publish(o) 
#     flash[:notice] = 'Successfully published the content.'
#   else
#     flash[:notice] = 'Error publishing the page.'
#   end
#   redirect_to(:action => 'show_content', :id => o.id, :content_template_id => t.id)
# end

  def clone_or_transfer_template_content
    @otu = Otu.find(params[:id])
    @transfer_to_otu  = Otu.find(params[:transfer_otu][:id])
    @content_template = ContentTemplate.find(params[:content_template_id])
    
    if @otu && @content_template && @transfer_to_otu     
      begin
        @content_template.transfer_to_otu(@otu, @transfer_to_otu, (params[:delete_after].blank? ? false : true))
        flash[:notice] = "Successfully transferred!  Viewing transferred to OTU."
        redirect_to(:action => :show_content, :id => @transfer_to_otu, :content_template_id => @content_template.id) and return
      rescue
      end
    end

     flash[:notice] = " Problem with transfer. "
     render :action => :show_content, :id => @otu, :content_template_id => @content_template
  end


  def batch_load
  end

  def batch_verify
    if params[:temp_file][:file].blank?
      flash[:notice] = "Choose a text file with your OTUs in it before verifying!"
      redirect_to(:action => :batch_load) and return  
    end
   
	  @ref = Ref.find(params[:otu][:ref_id]) if params[:otu]  &&  !params[:otu][:ref_id].blank?
	  @otu_group = OtuGroup.find(params[:otu][:otu_group_id]) if params[:otu]  && !params[:otu][:otu_group_id].blank?
	
    # read the contents of the uploaded file, split on pairs of newlines or '---', strip each one and add a newline
    @otus = params[:temp_file][:file].read.split(/\n/m).map {|x| x.strip}
  end

  def batch_create
    @count = 0

	  @ref = Ref.find(params[:ref_id]) if params[:ref_id] 
	  @otu_group = OtuGroup.find(params[:otu_group_id]) if params[:otu_group_id]
	
    begin
      Otu.transaction do
        for o in params[:otu].keys
          if params[:check][o]
            otu = Otu.new(:name => params[:otu][o])
            otu.as_cited_in = @ref.id if @ref
            otu.save!
            @otu_group.otus << otu if @otu_group
            @count += 1
          end
        end
      end

    rescue
      flash[:notice] = "Something went wrong."
      redirect_to :action => :batch_load and return
    end
     
    flash[:notice] = "Successfully added #{@count} OTUs." 
    redirect_to :action => :batch_load
  end


  ####
  ## below here is experimental
  ###

  ## what is this??? ... dunno, but it looks kinda cool
  def tree
    @otus = Otu.find_by_sql([
    "SELECT o.*, t.name as foo, t.iczn_group as bar FROM otus o 
    LEFT JOIN taxon_names t ON t.id = o.taxon_name_id  
    WHERE o.proj_id = ? and o.id < 1800 ORDER BY t.l", @proj.id])
  end  

  
  #def list2
  #
  #  @heads = HashFactory.call
  #  
  #  @heads[:unplaced][:otus] = Otu.find(:all, :conditions => {:taxon_name_id => nil, :proj_id => @proj.id}, :order => :name)
  #  @heads[:unplaced][:name] = 'unplaced'
  #  
  #  @proj.taxon_names(true).collect{|o|
  #     @heads[o.id][:name] = o.display_name;
  #     @heads[o.id][:otus] = o.child_otus(@proj.id) 
  #  } 
  #end
  
  # test
  def eol_test
    @xml = Eol::foo
  end


  def list_by_scope
    if params[:arg]
      @otus = @proj.otus.send(params[:scope],params[:arg]).ordered_taxonomically
    else
      @otus = @proj.otus.send(params[:scope]).ordered_taxonomically
    end 
    @list_title = "OTUs #{params[:scope].humanize.downcase}" 
    render :action => :list_simple
  end

  protected
  
  def list_params
    # project specific, so only find member of current project
    if session['group_ids'] && session['group_ids']['otu']
      @otu_group = OtuGroup.find(session['group_ids']['otu'])
      @otu_pages, @otus = paginate :otus, :per_page => 20, :conditions => "((proj_id = #{@proj.id}) and (otu_group_id = #{session['group_ids']['otu']}))",
      :join => "as o inner join otu_groups_otus on otu_groups_otus.otu_id = o.id", :include => [:taxon_name], :order => 'taxon_names.l, otus.name, otus.matrix_name'
    else
      @otu_pages, @otus = paginate :otus, :per_page => 20, :conditions => "(proj_id = #{@proj.id})", :include => [{:taxon_name => :parent}, :creator, :updator], :order => 'taxon_names.l, otus.name, otus.matrix_name'
    end
    @default_otu_group = OtuGroup.find(session['group_ids']['otu']) if session['group_ids'] && session['group_ids']['otu']  
  end

  # see before_filter, used in all 'show' calls
  def show_params 
    id = params[:otu][:id] if params[:otu] # for autocomplete/ajax picker use (must come first!)
    id ||= params[:id]
    @parents = []
    @default_chr_group = ChrGroup.find(session['group_ids']['chr']) if session['group_ids'] && session['group_ids']['chr']  

    if @otu = Otu.find(:first, :conditions => ["id = ?", id]) 
      @syn_otus = @otu.all_synonymous_otus
      @parents =  @otu.taxon_name.parents if @otu.taxon_name 
    else
     flash[:notice] =  "can't find that OTU!"  
     redirect_to :action => 'list', :controller => 'otu'
   end
   true
  end

  # Content
  def compare_params
    @left_otu = Otu.find(params[:left_otu][:id]) unless params[:left_otu][:id].empty?
    @right_otu = Otu.find(params[:right_otu][:id]) unless params[:right_otu][:id].empty?
 
    @content_type = ContentType.find(params[:content_type][:id])
  
    @left_lock = params[:left][:lock]
    @right_lock = params[:right][:lock]
     
    @left_content = Content.find(:first, :conditions => "content_type_id = #{@content_type.id} and otu_id = #{@left_otu.id}") if @left_otu
    @right_content = Content.find(:first, :conditions => "content_type_id = #{@content_type.id} and otu_id = #{@right_otu.id}") if @right_otu
  end

end
