class MxesController < ApplicationController
  include ActionView::Helpers::TextHelper
  require 'nexml/nexml'


  before_filter :set_export_variables, :only => [:show_nexus, :show_tnt, :show_ascii, :as_file]
  before_filter :set_grid_coding_params, :only => [:show_grid_coding, :show_grid_coding2, :show_grid_tags]
  before_filter :set_coding_variables, :only => [:code, :code_cell]

  def browse2
    @mx = @proj.mxes.first
    render :layout => false
  end 

  def index
    list
    render :action => 'list'
  end

  def list
    @mxes = Mx.by_proj(@proj)
    .page(params[:page])
    .per(20)
    .order('name')
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
    @otus = @mx.otus
    @otus_plus = @mx.otus_plus
    @otus_minus = @mx.otus_minus
    @otu_groups_in = @mx.otu_groups
    @otu_groups_out = @proj.otu_groups - @otu_groups_in
    @hash_heat = @mx.percent_coded_by_otu
    @chr = @mx.chrs_mxes.first.chr # first chr to point 'code' at
    @no_right_col = true
    render :action => :show
  end

  def show_characters
    @mx = Mx.find(params[:id])
    @chrs = @mx.chrs
    @chrs_plus = @mx.chrs_plus
    @chrs_minus = @mx.chrs_minus
    @chr_groups_in = @mx.chr_groups
    @chr_groups_out = @proj.chr_groups - @chr_groups_in
    @hash_heat = @mx.percent_coded_by_chr
    @otu = @mx.mxes_otus.first.otu # first otu to 'code' at
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
      notice 'Mx was successfully created.'
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
      notice 'Mx was successfully updated.'
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
      notice 'Matrix destroyed.'
    rescue
      notice "Error destroying matrix: #{@mx.errors.collect{|e| e.message.to_s}.join(";")}."
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
      notice "This is the cloned matrix."
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
      notice "This character group generated from #{@mx.name}."
      redirect_to :action => :show, :controller => :chr_groups, :id => @group and return
    when :otu_group
      @group = @mx.generate_otu_group
      notice "This OTU group generated from #{@mx.name}."
      redirect_to :action => :show, :controller => :otu_groups, :id => @group and return
    when :concensus_otu
      @mx.generate_concensus_otu
      redirect_to :action => :show, :id => @mx.id and return
    else
      # do nothing
    end
    notice 'Something went wrong.'
    redirect_to :action => :index
  end

  def code_with
    redirect_to :action => :code, :chr_id => params[:chr_id], :otu_id => params[:otu_id], :mode => params[:mode], :id => params[:mx][:id]
  end

  def otus_select
    # where else does this get called?
    if mx = Mx.find(params[:mx][:id])
      @otus = mx.otus
    else
      @otus = []  
    end
  end

  # --- Cell coding ---

  def cell_zoom
    @x = params[:x]
    @y = params[:y]
    @otu = Otu.find(params[:otu_id])
    @chr = Chr.find(params[:chr_id])
    @mx = Mx.find(params[:id])
    @confidences = []
    @codings = Mx.codings_for_code_form(:chr => @chr, :otu => @otu, :ref => @ref, :confidence => nil)
    render :template => 'mxes/cell/cell_zoom'
  end

  def update_cell 
    @success = true
    @x = params[:x]
    @y = params[:y]
    @otu = Otu.find(params[:otu_id])
    @chr = Chr.find(params[:chr_id])
    # @mx_id = params[:id]
    Mx.code_cell(params)
    @codings = Coding.where(:otu_id => @otu.id, :chr_id => @chr.id)
    render :template => 'mxes/cell/update_cell'
  end

  # This is a method that is called in the coding view.
  # It does an AJAX POST to here, and you need to re-render the coding view
  # So that you'll redraw any of the HTML which need to be re-rendered.
  def set_coding_mode
    session[:coding_mode] = params[:coding_mode].blank? ? :standard : :one_click
    notice "Set coding mode to #{session[:coding_mode].to_s.titleize}"
    redirect_to params[:return_to]
  end

  def set_coding_options
    session[:coding_default_confidence_id] = params[:confidence][:id]
    session[:coding_default_ref_id] = params[:ref][:id]
    notice "Updated default confidence and references." 
    redirect_to params[:return_to]
  end

  # Incoming variables set in #set_coding_variables 
  def code_cell
    # Code the cell (logic in code_cell here)
    codings = Mx.code_cell(params)

    # Navigate between cells if you are in on click
    if @coding_mode == :one_click 
      @position += 1
      if @mode == 'row'
        unless @chrs.length > @position
          notice "You've finished one-click coding for that OTU."
          redirect_to :action => :show_otus, :id => @mx.id and return
        end
      @chr = @chrs[@position] # update the @chr, the @otu stays the same
      elsif @mode == 'col'
        unless @otus.length > @position
          notice "You've finished one-click coding for that character."
          redirect_to :action => 'show_characters', :id => @mx.id and return
        end
      @otu = @otus[@position]  # update the @otu, the @chr stays the same
      else
        raise
      end
    end

    # TODO: This really is not optimal, because we have to laod all the variables again
    # Ideally (in the AJAX call here) we'd just render the template 'mxes/code/code' without the redirect
    # If we get here in a standard POST we'd get a :code_cell action in the URL/browser using a render :template, which we don't want
    redirect_to code_mx_path(@proj, @mx, @mode, @position, @chr, @otu) 
  end

  # Incoming variables set in #set_coding_variables 
  # No navigation between cells occurs here, this just renders the requested cell
  def code
    render :template => 'mxes/code/code' 
  end

  # --- End Cell Coding ---

  def code_matrix
    codings = Mx.code_cell(params)
    notice "Codings saved."
    redirect_to :action => :matrix_coding, :otu_id => params[:otu_id], :id => params[:id] 
  end

  def matrix_coding
    @matrices = @proj.mxes
    @mx = Mx.find(params[:set_id].blank? ? params[:id] : params[:set_id])
    if @mx.otus.count > 50
      @otus =  [] # @mx.otus.includes(:taxon_name) 
    else
      @otus = @mx.otus.includes(:taxon_name)
    end
    @otu = Otu.find(params[:otu_id]) if params[:otu_id]
    @otu ||= @mx.otus.first
    notice "Matrix set to to #{@mx.display_name}. <br />OTU set to #{@otu.display_name}.".html_safe 
    @codings = Coding.where(:chr_id => @mx.chrs, :otu_id => @otu).includes(:chr_state).
      inject({}){|hsh, c| hsh.merge("#{c.chr_id}A#{c.otu_id}B#{c.chr_state_id}" => c)}
    render :template => 'mxes/code/matrix/index' 
  end

  #== Managing characters

  def add_chr
    @mx = Mx.find(params[:mx][:id])
    begin
      if !params[:chr_group_id].blank?
        @mx.add_group(ChrGroup.find(params[:chr_group_id]))
        notice "Added a character group."
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
      notice "Problem with the addition, is choice, ready present?"
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
        notice "Added a character group."
      rescue
        notice "Problem adding character group, is it already present?"
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
      notice 'order reset'
    else
      redirect_to :action => :list
      notice "Can't find matrix with id #{params[:id]}."
    end
    redirect_to :action => :show_sort_otus, :id => @mx.id
  end


  def sort_otus
    params[:mxes_otu].each_with_index do |id, index|
      MxesOtu.update_all(['position=?', index+1], ['id=?', id])
    end

    notice "Order updated."
    render :nothing => true
  end

  #
  # Character sorting
  #

  def show_sort_characters
    @mx = Mx.find(params[:id])
    @chrs_mxes = @mx.chrs_mxes
    @no_right_col = true
    render :action => :show, :id => @mx.id and return
  end

  def sort_chrs
    params[:chrs_mx].each_with_index do |id, index|
      ChrsMx.update_all(['position=?', index+1], ['id=?', id])
    end
    notice "Order updated."
    render :nothing => true
  end


  
  def reset_chr_positions
    if @mx = Mx.find(params[:id])
      @mx.reset_chr_positions
      notice 'order reset'
    else
      redirect_to :action => :list
      notice "Can't find matrix with id #{params[:id]}."
    end
    redirect_to :action => :show_sort_chrs, :id => @mx
  end

    def invalid_codings
    @invalid_codings = Coding.invalid(@proj.id)
  end

  # misc
  def auto_complete_for_mxes
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
    @matrix = Mx.find(params[:id])
    @total_chrs = @matrix.chrs.count
    @total_otus = @matrix.otus.count

    if @total_chrs == 0 || @total_otus == 0
      warn "Populate your matrix with some characters or OTUs before browsing it."
      redirect_to :action => :show, :id => @matrix and return
    end

    if !params[:overlay].blank?
      @cell_type = params[:overlay] 
    else
      @cell_type = session['mx_overlay'] if !session["mx_overlay"].blank?
      @cell_type ||= 'none'
    end
    session["mx_overlay"] = @cell_type

    person = Person.find($person_id)
    
    if !params[:slide].blank?
      @window = @matrix.slide_window(params)
    else
      @window = {:chr_start => 1, :otu_start => 1, :chr_end => person.pref_mx_display_width || 1, :otu_end => person.pref_mx_display_height || 1}
    end

    @mx = @matrix.codings_in_grid(@window)   
    @oes = @window[:otu_end] - @window[:otu_start]
    @ces = @window[:chr_end] - @window[:chr_start]
    render :template => 'mxes/browse/browse'
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

  # TODO protect ? deprecated?
 #def _get_window_params
 #  @window = @matrix.slide_window(params)
 #  @oes = @window[:otu_end] - @window[:otu_start];  @ces = @window[:chr_end] - @window[:chr_start]
 #  @mx = @matrix.codings_in_grid(@window)
 #end

  def _cell_zoom
    @x = params[:x]
    @y = params[:y]
    @otu = Otu.find(params[:otu_id])
    @chr = Chr.find(params[:chr_id])
    @confidences = @proj.confidences
    @mx = Mx.find(params[:mx_id])
  end

  def otu_zoom
    @matrix = Mx.find(params[:id])
    @otu = Otu.find(params[:otu_id])
    @unique_codings = @otu.unique_codings
    render :template => 'mxes/browse/otu_zoom'
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

  def set_coding_variables
    # Set the incoming variables
    # regardless of whether we navigate with AJAX or not, we need these:
    @mx = Mx.includes({:otus => :taxon_name}, :chrs).find(params[:id])  # We never need the full matrix, just a slice
    @mode = params[:mode]               # 'row' or 'col', depending on the direction we're coding
    @position = params[:position].to_i

    @otus = @mx.otus
    @chrs = @mx.chrs 

    @coding_mode = session[:coding_mode] ? session[:coding_mode] : :standard
    @confidence  = session[:coding_default_confidence_id].blank? ? nil : Confidence.find(session[:coding_default_confidence_id]) 
    @ref         =  session[:coding_default_ref_id].blank? ? nil :  Ref.find(session[:coding_default_ref_id]) 
    @confidences = Confidence.where(:proj_id => @proj.id, :applicable_model => 'mx') 

    # Pull up a particular Otu and Chr based on position and coding mode
    if @mode == 'row'
      @otu = Otu.includes({:taxon_name => :parent}).find(params[:otu_id]) 
      @chr = @chrs[@position]
      @last_otu = @otu 
      @last_chr = @chrs[@position - 1] 
    elsif @mode == 'col'
      @otu = @otus[@position]
      @chr = Chr.includes({:chr_states => [:codings, :figures]}).find(params[:chr_id]) 
      @last_otu = @otus[@position - 1]
      @last_chr = @chr
    end

    @codings = Mx.codings_for_code_form(:chr => @chr, :otu => @otu, :ref => @ref, :confidence => @confidence)
    # TODO: toggle this
    @vector_nav_codings = Coding.for_vector_nav(@chr.id, @chrs.collect{|c| c.id}, @otu.id, @otus.collect{|o| o.id})
    @previous_position ||= @position  # TODO: might be able to avoid this
  end

  def set_export_variables
    @mx = Mx.find(params[:id])
    @multistate_characters = @mx.chrs.that_are_multistate
    @continuous_characters = @mx.chrs.that_are_continuous
    @otus = @mx.otus
    @codings_mx = @mx.codings_mx
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
