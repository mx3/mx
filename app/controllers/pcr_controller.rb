class PcrController < ApplicationController
  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }

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

  def list_params
    @pcr_pages, @pcrs = paginate :pcr, :per_page => 30,  :conditions => ['proj_id = (?)', @proj.id]
  end

  def list_by_scope
    if params[:arg]
      @pcrs = @proj.pcrs.send(params[:scope],params[:arg])
    else
      @pcrs = @proj.pcrs.send(params[:scope])
    end 
    @list_title = "PCRs #{params[:scope].humanize.downcase}" 
    render :action => :list_simple
  end

  def list_in_range
    @pcrs = []
    if request.post?
      if (params[:start] > params[:end]) || params[:start].blank? || params[:end].blank?
        flash[:notice] = "Bad range."
        redirect_to :action => :list_in_range and return
      end
      @pcrs = Pcr.find((params[:start].to_i..params[:end].to_i).to_a) 
    end
  end

  def show
    @pcr = Pcr.find(params[:id])
    @gel_image = GelImage.find(@pcr.gel_image_id) if @pcr.gel_image_id
  end

  def new
    @pcr = Pcr.new
  end

  def create
    @pcr = Pcr.new(params[:pcr])

    # wrap it in a transaction, modeled after images

    begin
      Pcr.transaction do
        if  params[:gel_image][:file].size != 0
          @gel_image = GelImage.new(params[:gel_image])
          @gel_image.save!
        end

        @pcr.gel_image_id = @gel_image.id if @gel_image
        @pcr.save!

        flash[:notice] = 'Pcr was successfully created.'
        redirect_to :action => 'show', :id => @pcr
      end
    rescue ActiveRecord::RecordInvalid
      flash[:notice] = 'Failed to load gel image.'
      render :action => 'new' and return
    end
  end

  def edit
    @pcr = Pcr.find(params[:id])
  end

  def update
    @pcr = Pcr.find(params[:id])
    if @pcr.update_attributes(params[:pcr])
      flash[:notice] = 'Pcr was successfully updated.'
      redirect_to :action => 'show', :id => @pcr
    else
      render :action => 'edit'
    end
  end

  def destroy
    Pcr.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def batch_pcr
    session["#{$person_id}_batch_pcr_rendered_once"] = false 
  end

  def _worksheet
    redirect_to :action => :batch_pcr and return if session["#{$person_id}_batch_pcr_rendered_once"]
    @pcrs = []

    begin 
      if !@pcrs = Pcr.batch_create(params.merge(:proj_id => @proj.id, :person_id => $person_id) ) 
        flash[:notice] = "Something went wrong during creation, you likely didn't select any extracts."
        redirect_to :back and return
      end

      @fwd_primer = Primer.find(params[:pcr][:fwd_primer_id])
      @rev_primer = Primer.find(params[:pcr][:rev_primer_id])

      v = params[:batch]
      t = @pcrs.size + 2

      @dntp = v[:dntp].to_f
      @buffer = v[:buffer].to_f
      @mg = v[:mg].to_f
      @taq = v[:taq].to_f
      @primers = v[:primers].to_f  # Pcr.default_vol[:primers] # v[:primers].to_f
      @templ = v[:template].to_f
      @other = v[:other].to_f

      @rxn_vol = v[:rxn_vol].to_f

      @water_per_single_rxn = @rxn_vol - (@dntp + @buffer + @mg + @taq + (@primers * 2) + @templ + @other)

      @t_dntp = @dntp * t 
      @t_buffer = @buffer * t 
      @t_mg =  @mg * t
      @t_primers = @primers * t 
      @t_taq = @taq * t 
      @t_other = @other * t
      @t_water = @water_per_single_rxn * t

      @done_by = params[:done_by]
      @protocol = Protocol.find(params[:pcr][:protocol_id]) if params[:pcr] && !params[:pcr][:protocol_id].blank?

      @notes = params[:pcr_notes]
      session["#{$person_id}_batch_pcr_rendered_once"] = true
      render :layout => :none 
    rescue
      flash[:notice] = "Something went wrong.  Were both fwd and rev primers selected?"
      redirect_to :back and return
    end
  end

  def _add_extract_to_batch
    e = Extract.find(params[:extract][:id])
    render :update do |page|     
      page.insert_html :bottom, :extracts, :partial => '/extract/extract_line_item', :object => e, :locals => {:pcr_batch_link => true, :i => Time.now.to_i}
    end and return
  end

  def _batch_add_extracts_to_batch
    if params[:past_two_weeks]
      @extracts = @proj.extracts.recently_changed
    elsif params[:without_pcrs]
      @extracts = @proj.extracts.without_pcrs
    elsif params[:last_20]
      @extracts = @proj.extracts.recently_changed(:limit => 20)
    else
      @extracts = []
    end    

    render :update do |page|    
      @extracts.each_with_index do |e, i| 
        page.insert_html :bottom, :extracts, :partial => '/extract/extract_line_item', :object => e, :locals => {:pcr_batch_link => true, :i => Time.now.to_i + i}
      end
    end and return
  end

  def _batch_add_extracts_to_batch_via_tags
    if params[:keyword][:id]
      @extracts = @proj.extracts.tagged_with_keyword(Keyword.find(params[:keyword][:id])) 
    end

    render :update do |page|    
      @extracts.each_with_index do |e, i| 
        page.insert_html :bottom, :extracts, :partial => '/extract/extract_line_item', :object => e, :locals => {:pcr_batch_link => true, :i => Time.now.to_i + i}
      end
    end and return
  end

  def _batch_add_extracts_to_batch_via_confidence
    if params[:confidence_id] && !params[:gene].blank? && !params[:gene][:id].blank?
      @extracts = @proj.extracts.by_confidence_from_status(params[:confidence_id]).by_gene_from_status(params[:gene][:id])
    elsif params[:confidence_id]
      @extracts = @proj.extracts.by_confidence_from_status(params[:confidence_id])
    end

    render :update do |page|    
      @extracts.each_with_index do |e, i| 
        page.insert_html :bottom, :extracts, :partial => '/extract/extract_line_item', :object => e, :locals => {:pcr_batch_link => true, :i => Time.now.to_i + i}
      end
    end and return
  end


  def _remove_extract_from_batch
    render :update do |page|
      page.remove params[:id]
    end and return
  end

  def auto_complete_for_pcr
    @tag_id_str = params[:tag_id]
    value = params[@tag_id_str.to_sym]
    @pcrs = Pcr.find_for_auto_complete(value)
    render :inline => "<%= auto_complete_result_with_ids(@pcrs,
      'format_obj_for_auto_complete', @tag_id_str) %>"
  end



end
