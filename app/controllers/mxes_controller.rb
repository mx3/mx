class MxesController < ApplicationController

  # TODO: this should be elsewhere?
  include ActionView::Helpers::TextHelper
  require 'nexml/nexml'
  # include Nexml::Nexml

  before_filter :set_export_variables, :only => [:show_nexus, :show_tnt, :show_ascii, :as_file]
  before_filter :set_grid_coding_params, :only => [:show_grid_coding, :show_grid_coding2, :show_grid_tags]

  layout "layouts/application",  :except => [:as_file]

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

  def show
    id = params[:mx][:id] if params[:mx] # for autocomplete/ajax picker use (must come first!)
    id ||= params[:id] 
    @mx = Mx.find(id)
   
    respond_to do |format|
      format.html {
        @show = ['default'] # not redundant with above- @show necessary for multiple display of items 
      }
      format.xml {
        @xml = serialize(:mx => @mx)
        render :xml => @xml, :layout => false
      }
      format.rdf {
        @xml = serialize(:mx => @mx, :rdf => true)
        render :xml => @xml, :layout => false
      }
    end
  end

  def show_unused_character_states
    @mx = Mx.find(params[:id])
    @unused_chr_states = @mx.unused_chr_states.sort{|a,b| a.chr.name <=> b.chr.name}
    @no_right_col = true
    render :action => :show
  end

  def show_trees
    @mx = Mx.find(params[:id]) 
    @trees = @mx.trees
    @no_right_col = true
    render :action => :show
  end

  def show_otus
    @mx = Mx.find(params[:id])
    _set_otus
    @chr = @mx.chrs.first # first chr to point 'code' at 
    @no_right_col = true
    render :action => :show
  end

  def show_characters
    @mx = Mx.find(params[:id])  
    _set_chrs
    @otu = @mx.otus.first # first otu to 'code' at
    @no_right_col = true
    render :action => :show
  end

  def show_batch_code
    @mx = Mx.find(params[:id])  
    @chrs = @mx.chrs
    @otus = @mx.otus
    @no_right_col = true
    render :action => :show
  end

  def show_data_sources
    @mx = Mx.find(params[:id], :include => :data_sources)  
    @no_right_col = true
    render :action => :show
  end

  def show_figures
    @mx = Mx.find(params[:id], :include => :data_sources)  
    @no_right_col = true
    render :action => :show
  end

  def show_nexus
    # see before_filter set_export_variables  
    @no_right_col = true
    render :action => :show
  end

  def show_tnt
    # see before_filter set_export_variables  
    @no_right_col = true
    render :action => :show
  end

  def show_ascii
    # has its own layout
    # see before_filter set_export_variables  
    @interleave_width = Person.find($person_id).pref_mx_display_width 
    render :layout =>  false, :action => 'export/show_ascii' 
  end

  def new
    @mx = Mx.new
  end

  def create
    @mx = Mx.new(params[:mx])
    if @mx.save
      flash[:notice] = 'Mx was successfully created.'
      redirect_to :action => 'show', :id => @mx.id
    else
      render :action => :edit
    end
  end

  def edit
    @mx = Mx.find(params[:id])
  end

  def update
    @mx = Mx.find(params[:id])
    if @mx.update_attributes(params[:mx])
      flash[:notice] = 'Mx was successfully updated.'
      redirect_to :action => 'show', :id => @mx.id
    else
      render :action => :edit
    end
  end

  def destroy
    @mx = Mx.find(params[:id])
    begin
      Mx.transaction do
        @mx.destroy 
      end
      flash[:notice] = 'Matrix destroyed.'
    rescue 
      flash[:notice] = "Error destroying matrix: #{@mx.errors.collect{|e| e.message.to_s}.join(";")}."
    end
    redirect_to :action => :list
  end

  def as_file
    # see before_filter set_export_variables 
    @as_file = true
    case params[:filetype].to_sym
    when :tnt
      f = render_to_string(:partial => "/mx/export/tnt", :layout => false)
      filename = 'mx_matrix.tnt'
    when :nexml
      filename = 'mx_matrix.xml'
      f = serialize(:mx => @mx)
    end
    send_data(f, :filename => filename, :type => "application/rtf", :disposition => "attachment")
    # DO NOT USE REDIRECT/RENDER HERE
  end

  def clone
    mx = Mx.find(params[:id])
    case params[:clone_type].to_sym
    when :simple
      @mx = mx.clone_to_simple 
      flash[:notice] = "This is the cloned matrix."
    else
      # do nothing
    end
    redirect_to :action => :show, :id => @mx.id
  end

  def generate
    @mx = Mx.find(params[:id])
    case params[:generate_type].to_sym
    when :chr_group
      @group = @mx.generate_chr_group
      flash[:notice] = "This character group generated from #{@mx.name}."
      redirect_to :action => :show, :controller => :chr_groups, :id => @group and return
    when :otu_group
      @group = @mx.generate_otu_group
      flash[:notice] = "This OTU group generated from #{@mx.name}."
      redirect_to :action => :show, :controller => :otu_groups, :id => @group and return
    when :concensus_otu
      @mx.generate_concensus_otu
      redirect_to :action => :show, :id => @mx.id and return
    else
      # do nothing
    end
    flash[:notice] = 'Something went wrong.'
    redirect_to :action => :index
  end

  # TODO: move logic to model where possible
  # This method provides one-click coding, iterating through either chrs or OTUs
  # It handles both the post and show aspects.
  def fast_code
    id = params[:mx][:id] if params[:mx] # for autocomplete/ajax picker use (must come first!)
    id ||= params[:id] 

    # regardless of whether we navigate with ajax, or by post, we need these:
    @mx = Mx.find(id)
    @confidences = @proj.confidences
    @mode = params[:mode]                       # 'row' or 'col', depending on the direction we're coding
    @present_position = params[:position].to_i

    # general setup
    @tag = Tag.new
    @no_right_col = true

    @otus = @mx.otus
    @chrs = @mx.chrs

    # Pull up a particular Otu and Chr based on present_position
    # this block checks for Ajax, the checks below check for POST
    if @mode == 'row'
      unless @chrs.length > @present_position
        flash[:notice] = "You've finished one-click coding for that OTU."
        redirect_to :action => :show_otus, :id => @mx.id and return
      end
      @otu = Otu.find(:first, :conditions => {:proj_id => @proj.id, :id => params[:otu_id]}, :include => [{:taxon_name => :parent}])
      @chr = @chrs[@present_position]
    elsif @mode == 'col'
      unless @otus.length > @present_position
        flash[:notice] = "You've finished one-click coding for that character."
        redirect_to :action => 'show_characters', :id => @mx.id and return
      end
      @chr = Chr.find(:first, :conditions => {:proj_id => @proj.id, :id => params[:chr_id]}, :include => [:chr_states])
      @otu = @otus[@present_position]
    else
      redirect_to :action => :index and return # illegal mode
    end

    # add/delete actions
    if params[:nuke] == 'true'   # nuke states for this combination, comes in as get?
      Coding.destroy_by_otu_and_chr(Otu.find(params[:otu_id]), Chr.find(params[:chr_id]))
    elsif request.post?
      if !params[:chr_state_id].blank? || !params[:continuous_value].blank? # we navigated here from another form
        @coding = Mx.fast_code(params.merge(:chr => @chr, :otu => @otu))
        @present_position = @present_position + 1
      end
    end

    # A lot of this code is repeated from above, but that avoids the need to call this action
    # twice per coding, which improves performance a lot
    if @mode == 'row'
      @chr = @chrs[@present_position]
      unless @chrs.length > @present_position # these check for POST, the checks above check for AJAX
        flash[:notice] = "You've finished one-click coding for that OTU."
        redirect_to :action =>'show_otus', :id => @mx.id and return
      end
    elsif @mode == 'col'
      unless @otus.length > @present_position # these check for POST, the checks above check for AJAX
        flash[:notice] = "You've finished one-click coding for that character."
        redirect_to :action =>'show_characters', :id => @mx.id and return
      end
      @otu = @otus[@present_position]
    end

    @last_otu = (@mode == 'row' ? @otu : @otus[@present_position - 1])
    @last_chr = (@mode == 'col' ? @chr : @chrs[@present_position - 1])
    @previous_position ||= @present_position
      
    # render the updates
    respond_to do |format|
      format.html {
        @show = ['fast_coding']
        render :action => :show
      }
      format.js { # AJAX
        render :update do |page|
          page.replace_html :notice, flash[:notice]
          page.replace_html :fast_coding_form, :partial => 'fc'
          flash.discard
        end and return }
    end
  end

  def show_code
    @mx = Mx.find(params[:id])
    @otu = Otu.find(params[:otu_id])
    @chr = Chr.find(params[:chr_id])
    @confidences = @proj.confidences

    codings = []
    # move logic to model? 
    if request.post?
      @codings = Coding.by_chr(@chr).by_otu(@otu)

      if @chr.is_continuous
        @codings.destroy_all
        
        coding = Coding.create(
          "otu_id" => @otu.id,
          "chr_id" => @chr.id,
          "continuous_state" => params[:continuous_value],
          # "chr_state_state" => chr_state.state, # set on before_filter
          # "chr_state_name" => chr_state.name,
          :confidence_id => (params[:confidence] ? params[:confidence][chr_state.id.to_s] : nil),
          "proj_id" => @proj.id
        )

        codings.push coding

      else
        
        params[:state].each_pair { |chr_state_id, coded|
          chr_state = ChrState.find(chr_state_id.to_i)
          if (coding = @codings.detect {|c| c.chr_state_id == chr_state.id}) # coding exists? 
            if coded == "0"
              coding.destroy
            else # exists, but confidence might have changed
              coding.update_attributes(:confidence_id => ((params[:confidence] && params[:confidence][chr_state.id.to_s]) ? params[:confidence][chr_state.id.to_s] : nil) )
              codings.push coding
            end
          else # coding doesn't exist 
            if coded == "1"
              coding = Coding.create(
                "otu_id" => @otu.id,
                "chr_id" => @chr.id,
                "chr_state_id" => chr_state.id,
                # "chr_state_state" => chr_state.state, # set on before_filter
                # "chr_state_name" => chr_state.name,
                :confidence_id => (params[:confidence] ? params[:confidence][chr_state.id.to_s] : nil),
                "proj_id" => @proj.id 
              ) 
              codings.push coding
            end
          end        
        }
      end

      flash[:notice] = "Updated."
    end
  
    if params[:from_grid_coding]
      # should make these locals 
      @x = params[:x]
      @y = params[:y]
      cell_type = session["#{$person_id}_mx_overlay"] if not session["#{$person_id}_mx_overlay"].blank?
      cell_type ||= 'none' 
      render :update do |page|
        page.replace_html :cell_zoom, :partial => 'grid_cell_zoom' 
        page.replace_html "cell_#{@x}_#{@y}", :partial => "/mx/cells/cell_#{cell_type}", :locals => {:i => params[:x], :j => params[:y], :o => @otu, :c => @chr, :mx_id => @mx.id, :codings => codings} 
      end and return
    else

      @adjacent_cells = @mx.adjacent_cells(:otu_id => @otu.id, :chr_id => @chr.id)
      @no_right_col = true
      render :action => :show, :id => @mx.id, :otu_id => @otu.id, :chr_id => @chr.id and return
    end
  end 
 
  #== Managing characters

  def add_chr
    @mx = Mx.find(params[:mx][:id])
    begin 
      if !params[:chr_group_id].blank?
        @mx.add_group(ChrGroup.find(params[:chr_group_id]))
        flash[:notice] = "Added a character group."
      end

      if params[:mx_chr] && !params[:mx_chr][:plus_id].blank?
        c = Chr.find(params[:mx_chr][:plus_id])
        @mx.chrs_plus << c if c
        @mx.save! 
      end

      if params[:mx_chr] && !params[:mx_chr][:minus_id].blank?
        c = Chr.find(params[:mx_chr][:minus_id])
        @mx.chrs_minus << c if c 
      end
    rescue
      flash[:notice] = "Problem with the addition, is choice, ready present?"
    end

    redirect_to :action => :show_characters, :id => @mx.id
  end

  def remove_chr
    @mx = Mx.find(params[:id])
    if @mx
      @mx.remove_group(ChrGroup.find(params[:chr_group_id])) if params[:chr_group_id]
      @mx.remove_from_plus(Chr.find(params[:chr_id])) if params[:chr_id]
      @mx.remove_from_minus(Chr.find(params[:minus_chr_id])) if params[:minus_chr_id]
    else
      render :action => :list and return
    end
    redirect_to :action => :show_characters, :id => @mx.id
  end

  # managing OTUs
  
  def add_otu
    redirect_to :action => :list and return if params[:mx].blank?
    @mx = Mx.find(params[:mx][:id])
    if !params[:otu_group_id].blank?
      begin
        @mx.add_group(OtuGroup.find(params[:otu_group_id]))
        flash[:notice] = "Added a character group."
      rescue
        flash[:notice] = "Problem adding character group, is it already present?"
      end
    end
     
    if params[:add_otu_minus]
      if params[:otu_minus] && !params[:otu_minus][:id].blank? 
        o = Otu.find(params[:otu_minus][:id])
        @mx.otus_minus << o if o
      end 
    elsif params[:add_otu_plus]
      if params[:otu_plus] && !params[:otu_plus][:id].blank? 
        o = Otu.find(params[:otu_plus][:id])
        @mx.otus_plus << o if o
      end 
    end

    @mx.save! 
    
    redirect_to :action => :show_otus, :id => @mx.id    
  end
 
  def remove_otu
    @mx = Mx.find(params[:id])
    if @mx 
      @mx.remove_group(OtuGroup.find(params[:otu_group_id])) if params[:otu_group_id]
      @mx.remove_from_plus(Otu.find(params[:otu_id])) if params[:otu_id]
      @mx.remove_from_minus(Otu.find(params[:minus_otu_id])) if params[:minus_otu_id]
    else
      render :action => :list and return
    end
    redirect_to :action => :show_otus, :id => @mx.id    
  end
  
  # otu sorting

  def show_sort_otus
    @mx = Mx.find(params[:id])
    @mxes_otus = @mx.mxes_otus
    @no_right_col = true
    render :action => :show, :id => @mx.id and return
  end


  def reset_otu_positions
    if @mx = Mx.find(params[:id])
      @mx.reset_otu_positions
      flash[:notice] = 'order reset'
    else
      redirect_to :action => :list
      flash[:notice] = "Can't find matrix with id #{params[:id]}."
    end
    redirect_to :action => :show_sort_otus, :id => @mx.id
  end


  def sort_otus
    params[:otus].each_with_index do |id, index|
      MxesOtu.update_all(['position=?', index+1], ['id=?', id])
    end
    render :nothing => true
  end


  # character sorting
  
  def show_sort_characters
    @mx = Mx.find(params[:id])
    @chrs_mxes = @mx.chrs_mxes
    @no_right_col = true
    render :action => :show, :id => @mx.id and return
  end

  def reset_chr_positions
    if @mx = Mx.find(params[:id])
      @mx.reset_chr_positions
      flash[:notice] = 'order reset'
    else
      redirect_to :action => :list
      flash[:notice] = "Can't find matrix with id #{params[:id]}."
    end
    redirect_to :action => :show_sort_chrs, :id => @mx
  end

  def sort_chrs
    params[:chrs].each_with_index do |id, index|
      ChrsMx.update_all(['position=?', index+1], ['id=?', id])
    end
    render :nothing => true
  end

  def invalid_codings
    @invalid_codings = Coding.invalid(@proj.id)
  end

  # misc
  def auto_complete_for_mx
    value = params[:term]
    if value.nil? 
      redirect_to(:action => 'list', :controller => 'mxes') and return
    else
      val = value.split.join('%') 
      @mxes = Mx.find(:all, :conditions => ["(name LIKE ? OR id = ?) AND proj_id=?", "%#{val}%", val.gsub(/\%/, ""), @proj.id], :order => "name")
    end
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @mxes, :method => params[:method])
  end

  def browse
    @matrix = Mx.find(params[:id], :include => [:chrs, :otus])
    @total_chrs = @matrix.chrs.count
    @total_otus = @matrix.otus.count
 
    if @total_chrs == 0 || @total_otus == 0
      flash[:notice] = "Populate your matrix with some characters or OTUs before browsing it."
      redirect_to :action => :show, :id => @matrix and return
    end 

    @cell_type = session["#{$person_id}_mx_overlay"] if !session["#{$person_id}_mx_overlay"].blank?
    @cell_type ||= 'none' 

    person = Person.find($person_id)

    respond_to do |format|
      
		  format.html {} # default .rhtml
      @window = {:chr_start => 1, :otu_start => 1, :chr_end => person.pref_mx_display_width, :otu_end => person.pref_mx_display_height}
      @mx = @matrix.codings_in_grid(@window)
        
      # simplify several calculations for the view
      @oes = @window[:otu_end] - @window[:otu_start] 
      @ces = @window[:chr_end] - @window[:chr_start]

      format.js { 
        _get_window_params 
        render :update do |page|
          page.replace_html :window_to_update, :partial => 'window'
          page.replace_html :cell_zoom, :text => nil
          # page.visual_effect :fade, "tl_#{@obj.class.to_s}_#{@obj.id}"
          # page.insert_html :bottom, "t_#{@obj.class.to_s}_#{@obj.id}", :partial => 'popup_form'
        end and return 
      }
		end
  end

  
  def owl_export
    matrix = Mx.find(params[:id])
    graph = RDF::Graph.new
    owl = OWL::OWLDataFactory.new(graph)
    matrix.otus.each do |otu|
      Ontology::Mx2owl.translate_otu(otu, owl)
    end
    matrix.codings.each do |coding|
      Ontology::Mx2owl.translate_coding(coding, owl)
    end
    matrix.chrs.each do |chr|
      Ontology::Mx2owl.translate_chr(chr, owl)
    end
    rdf = RDF::Writer.for(:ntriples).buffer {|writer| writer << graph }
    # when rdfxml gem is updated with bugfix (or we move to ruby 1.9) we can switch to next line
    #rdf = RDF::RDFXML::Writer.buffer {|writer| writer << graph }
    render(:text => (rdf))
  end


  # TODO protect
  def _get_window_params
    @window = @matrix.slide_window(params)
    @oes = @window[:otu_end] - @window[:otu_start];  @ces = @window[:chr_end] - @window[:chr_start]
    @mx = @matrix.codings_in_grid(@window)
  end

  def _cell_zoom
    @x = params[:x]
    @y = params[:y]
    @otu = Otu.find(params[:otu_id])
    @chr = Chr.find(params[:chr_id])
    @confidences = @proj.confidences
    @mx = Mx.find(params[:mx_id])
    render :update do |page|
      page.replace_html :cell_zoom, :partial => 'grid_cell_zoom'
    end
  end

  def _otu_zoom
    @matrix = Mx.find(params[:id])
    @otu = Otu.find(params[:otu_id])
    @unique_codings = @otu.unique_codings 
    render :update do |page|
      page.replace_html :cell_zoom, :partial => 'otu_zoom'
    end
  end

  def _set_overlay_preference
    @matrix = Mx.find(params[:id])
    session["#{$person_id}_mx_overlay"]  =  params[:overlay]
    _get_window_params
    render :update do |page|
      page.replace_html :window, :partial => 'grid_window', :locals => {:codings_in_grid => @mx, :mx_id => @matrix.id, :cell_type => params[:overlay] }
    end and return
  end

  def test
    mx = Mx.find(240)
    @xml = serialize(:mx => mx)
  
    respond_to do |format|
      format.html {
        @show = ['default'] # not redundant with above- @show necessary for multiple display of items 
      }
      format.xml {
        render :xml => @xml, :layout => false
        # re
        # render(:action => 'test', :layout => false) and return
      }
      format.rdf {
        @transform = true
        render :action => 'nexml/nexml', :layout => false
      }
    end
  end

  private
  
  def list_params
    @mx_pages, @mxes = paginate :mx, :per_page => 20, :order_by => 'name', :conditions => ['mxes.proj_id = (?)', @proj.id], :include => [:creator, :updator, :otus, :chrs]
  end

  def set_export_variables
    @mx = Mx.find(params[:id])  
    @multistate_characters = @mx.chrs.that_are_multistate
    @continuous_characters = @mx.chrs.that_are_continuous
    @otus = @mx.otus
    @codings_mx = @mx.codings_mx
  end


  # TODO: before_filter this if used elsewhere
  def _set_otus
    @otus = @mx.otus
    @otus_plus = @mx.otus_plus 
    @otus_minus = @mx.otus_minus
    @otu_groups_in = @mx.otu_groups
    @otu_groups_out = @proj.otu_groups - @otu_groups_in

    @hash_heat = @mx.percent_coded_by_otu
  end

  # before_filter this
  def _set_chrs
    @chrs = @mx.chrs

    @chrs_plus = @mx.chrs_plus 
    # @chrs_plus_out = @proj.chrs - @chrs  

    @chrs_minus = @mx.chrs_minus
    # @chrs_minus_out = @proj.chrs - @chrs_minus

    @chr_groups_in = @mx.chr_groups
    @chr_groups_out = @proj.chr_groups - @chr_groups_in

    @hash_heat = @mx.percent_coded_by_chr
  end

  # before_filter this
  def set_grid_coding_params
    @mx = Mx.find(params[:id])  
    @chrs = @mx.chrs
    @otus = @mx.otus

    @time = Benchmark.measure{
      @codings_mx =  @mx.codings_mx # codings_in_grid({})
    }.to_s

    session[:interleave_size] = params[:interleave_size] if params[:interleave_size]
    session[:interleave_size] ||= 20
  end

end
