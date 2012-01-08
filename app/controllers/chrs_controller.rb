require 'rdf'
require 'rdf/rdfxml'

class ChrsController < ApplicationController

  in_place_edit_for :chr, :notes
  in_place_edit_for :chr, :doc_char_descr

  def _in_place_notes_update
    c = Chr.find(params[:id])
    c.notes = params[:value]
    if c.save
      notice "Updated notes" 
      render :text => c.notes
    else
      error "Validation failed, record not updated."
     render :text => 'Validation failed, record not updated.', :status=>400 
    end
  end

  def _in_place_description_update
    c = Chr.find(params[:id])
    c.doc_char_descr = params[:value]
    if c.save
      notice "Updated description"
      render :text => c.doc_char_descr
    else
      error "Validation failed, record not updated"
      render :text => 'Validation failed, record not updated.', :status=>400
    end
  end

  def index
    list
    render :action =>  :list
  end

  def list
    @chrs = Chr.by_proj(@proj).page(params[:page]).per(20).includes({:cited_in_ref => :authors}, :chr_states, :creator, :updator, :codings)
  end

  def show
    id = params[:chr][:id] if params[:chr] # for autocomplete/ajax picker use
    id ||= params[:id]
    @chr = Chr.find(id)
    @chr_states = @chr.chr_states
    @chr_state = ChrState.new
    @show = ['default'] 
  end

  def show_otus_for_state
    @chr_state = ChrState.find(params[:id])
    @chr = Chr.find(@chr_state.chr_id) # should use :include
    @otus = @chr_state.otus 
    @no_right_col = true
    @show = ['coded_otus']
    render :action  => :show
  end

  def show_groups
    @chr = Chr.find(params[:id])
    @chr_groups = @chr.chr_groups
    @no_right_col = true
    render :action => :show
  end

  def show_mxes
    @chr = Chr.find(params[:id])
    @mxes = @chr.mxes
    @no_right_col = true
    render :action => :show
  end

  def show_edit_expanded
    @chr = Chr.find(params[:id])
    @l = Linker.new(:incoming_text => @chr.doc_char_descr, :proj_id => @proj.ontology_id_to_use, :adjacent_words_to_fuse => 5, :link_url_base => self.request.host)
    if @l.text_to_link.nil? 
      @linked_text = "No text to link" if @linked_text.nil?
    else
      @linked_text = @l.linked_text(:include_plural => true)
    end
    @no_right_col = true
    render :action => :show
  end

  def show_coded_otus
    # use group by here
    @chr = Chr.find(params[:id])  
    @otus = @chr.otus # Otu.find_coded_for(@chr.id)
    @no_right_col = true
    render :action => :show
  end

  def show_merge_states
    @chr = Chr.find(params[:id]) 
    @no_right_col = true
    render :action => :show
  end

  def new
    @chr = Chr.new
    @target = "create"
    @chr_groups = @proj.chr_groups
    render :action => :new
  end

  def create
    @chr = Chr.new(params[:chr])  
    params[:chr][:short_name] = params[:chr][:short_name][0..5] if params[:chr][:short_name].size > 6 # move to before_save filter
    if @chr.save
      if !params[:chr_group_id].blank?
        if @chr_group = ChrGroup.find(params[:chr_group_id])
          @chr_group.add_chr(@chr) 
        end
      end
      flash[:notice] = 'Character was successfully created.'
      redirect_to :action => 'show', :id => @chr.id # redirect_to :action => 'list'
    else
      render :action => :edit
    end
  end
  
  # states don't need their own controller, so they are dealt with in this one
  def add_state
    @chr_state = ChrState.new(params[:chr_state])

    if @chr_state.save
      flash[:notice] = 'State was successfully added.'
     else
      flash[:notice] = 'State NOT added- perhaps it already exists?'
    end
    
    redirect_to :action => :show, :id => params[:chr_state][:chr_id]
  end

  def edit
    @chr = Chr.find(params[:id], :include => [:cited_in_ref, :chr_states])    
    @target = "update" 
  end

  def update
    @chr = Chr.find(params[:chr][:id])
    
    # move to before save filter
    if params[:chr][:short_name]
      params[:chr][:short_name] = params[:chr][:short_name][0..5] if params[:chr][:short_name].size > 6
    end
    
    if @chr.update_attributes(params[:chr])
      # need to update the states
      params[:chr_state].each_value {|h| update_state(h) } if params[:chr_state] && !@chr.continuous?
      flash[:notice] = 'Chr was successfully updated.'
      redirect_to :action => :show, :id => @chr.id
    else
      @target = "update"
      render :action => :edit
    end
  end

  def update_state(state_h)
    @chr_state = ChrState.find(state_h['id'])
    @chr_state.update_attributes(state_h)
  end
  
  def destroy_state
    ChrState.find(params['chr_state_id']).destroy
    redirect_to :action => :show, :id => params['id']
  end
    
  def destroy
    Chr.find(params['id']).destroy
    redirect_to :action => :list
  end

  def list_states
    @chrs = @proj.chrs
    render :layout => "layouts/print", :action => "chrs/list_states" ## might need to update this => , "200" 
  end

  def list_by_char_group
    @chr_groups = @proj.chr_groups
    render :action => :list_by_char_group
  end

  def list_recent_changes_by_chr_state
    @chrs = Chr.by_proj(@proj).recently_changed_by_chr_state(1.week.ago, :limit => 50).page(nil).per(100) # Chr.find(:all, :limit => 20, :conditions => "(proj_id = #{@proj.id})", :include => 'chr_states',   :order => 'chr_states.created_on DESC, chr_states.updated_on DESC, chrs.id')
    @by_header = '(upto 50 most recent changes, by character state)'
    @hide_pagination = true
    render :template => 'chrs/list'
  end

  def list_recent_changes_by_chr
    @chrs = Chr.by_proj(@proj).recently_changed(1.week.ago, :limit => 50).page(nil).per(100)
    @by_header = '(upto 50 most recent changes, by character)'    
    @hide_pagination = true
    render :template => 'chrs/list'
  end


  def list_chars_not_in_matrices
    @chrs = @proj.chrs.not_in_matrices
    @by_header = '(not in matrices)'
    @hide_pagination = true
    render :template => 'chrs/list'
  end

  # TODO: where is this called?
  def add_to_group
    if @chr = Chr.find(params[:chr][:id])
      if @chr_group = ChrGroup.find(params[:chr_group_id])
        if @chr_group.add_chr(@chr)
         flash[:notice] = "added to group"
        else
         flash[:notice] =  "already a member"
        end 
      end
    end
    redirect_to :action => 'show_groups', :id => @chr.id
  end
  
  # TODO: DEFINITELY move to model
  def merge_states
      # the merge is really a replace function, as the old codings are deleted and replaced, but to the user it appears that you are merging them
      ## we should likely wrap this in a transaction for possible rollback, and move it too the Chr model
      
      @chr = Chr.find(params[:id])
      @s1 = params[:merge][:state1]
      @s2 = params[:merge][:state2]

      # check that legal states are passed and that the character actually has those states
       @states = @chr.chr_states.collect {|s| s.state}
       if not @states.include?(@s1) or not @states.include?(@s1)
             flash[:notice] = "Merge failed, one or both of the states doesn't exist" 
             redirect_to :action => :show_merge_states, :id => @chr.id and return
       end
     
      # check that the incoming chr_state is valid before deleting everything!
      if params[:merge][:new_state].empty? or params[:merge][:name].empty? 
             flash[:notice] = "Merge failed, you left the state or state name empty" 
             redirect_to :action => :show_merge_states, :id => @chr.id and return
      end
      
      # does the new state already exist and its not being merged? that's bad
      if (@states.include?(params[:merge][:new_state]) and (params[:merge][:new_state] != @s1 and params[:merge][:new_state] != @s2 ))
        flash[:notice] = "Merge failed, your new state #{params[:merge][:new_state]} is an existing state that you are not merging. Confused? You should be! See the help." 
        redirect_to :action => :show_merge_states, :id => @chr.id and return
      end
  
      # get the existing chrstate objects
      @cs1 = ChrState.find_by_chr_id_and_state(@chr.id, @s1)
      @cs2 = ChrState.find_by_chr_id_and_state(@chr.id, @s2)

      # make an array of old OTUs that had a coding for this character (scope update)
      @otus = Coding.find_by_sql(["SELECT DISTINCT otu_id FROM Codings WHERE ((chr_id = ?) and (proj_id = ?)  and ( (chr_state_id = ?) or (chr_state_id = ?) ) );", @chr.id, @proj.id, @cs1.id, @cs2.id])
      
      # delete the old codings if they exist (scope update again)
      @old_codings = Coding.find_by_sql(["SELECT id, otu_id, chr_id, chr_state_id, proj_id FROM Codings WHERE ((chr_id = ?) and (proj_id = ?) and ( (chr_state_id = ?) or (chr_state_id = ?) ) );", @chr.id, @proj.id, @cs1.id, @cs2.id])
      for coding in @old_codings
        Coding.find(coding.id).destroy
      end
      
      # delete the old chr_states
      @cs1.destroy
      @cs2.destroy
          
      # add the new state
      @cs = ChrState.new
      @cs.chr_id = @chr.id
      @cs.name = params[:merge][:name]
      @cs.state = params[:merge][:new_state]
      @cs.notes = params[:merge][:notes]
      @cs.save

      # loop the array and add the new codings

      for otu in @otus
        @cd = Coding.new
        @cd.otu_id = otu.otu_id
        @cd.chr_id = @chr.id
        @cd.chr_state_id = @cs.id
        @cd.chr_state_state = @cs.state
        @cd.chr_state_name =  @cs.name
        @cd.save
      end
      
      flash[:notice] = "merged successfully!" 
      redirect_to :action => :edit, :id => params[:id]
  end
 
  def list_all
    @chrs = @proj.chrs(:order => 'chrs.position')
  end
  
  def position_chr
    if o = Chr.find(params[:id])  
      o.send(params[:move])
      flash[:notice] = 'moved'
    end
      redirect_to :action => :list_all
  end
  
  # TODO: move to model
  def reset_order
    o = (params[:sort][:order] == 'ascending' ? 'ASC' : 'DESC')

    if @chrs = Chr.find(:all, :conditions => "proj_id = #{@proj.id}", :order => "#{params[:sort][:field]} #{o}")
      i = 1
      for o in @chrs
        o.position = i
        o.save
        i += 1
      end
      flash[:notice] = 'order reset'
    else
      flash[:notice] = 'problem reseting order'
    end
    redirect_to :action => 'list_all'
  end

  def clone_chr
    if chr = Chr.find(params[:id])
      @chr = chr.dupe
      redirect_to :action => :show, :id => @chr  and return
     end
      flash[:notice] = "Couldn't find character to clone."
      redirect_to :action => :edit, :id => chr.id
  end
      
 def doc_export
   @chrs = []
   if params[:id]
     @chrs << Chr.find(params[:id])
   elsif params[:chr_group_id]
     @chrs = ChrGroup.find(params[:chr_group_id]).chrs
   elsif params[:mx_id]
     @chrs = Mx.find(params[:mx_id]).chrs
   else # show them all
     @chrs = @proj.chrs
   end
   render :layout => false
 end
 
 def owl_export
   #TODO this duplicates some code from doc_export - should refactor
   @chrs = Array.new
    if params[:id]
      @chrs << Chr.find(params[:id])
    elsif params[:chr_group_id]
      @chrs = ChrGroup.find(params[:chr_group_id]).chrs
    elsif params[:mx_id]
      @chrs = Mx.find(params[:mx_id]).chrs
    else # show them all
      @chrs = @proj.chrs
    end
    graph = RDF::Graph.new
    owl = OWL::OWLDataFactory.new(graph)
    @chrs.each do |c|
      Ontology::Mx2owl.translate_chr(c, owl)
    end
    #triples = RDF::Writer.for(:ntriples).buffer {|writer| writer << graph }
    # when rdfxml gem is updated with bugfix we can switch to next line
    rdf = RDF::RDFXML::Writer.buffer {|writer| writer << graph }
    render(:text => (rdf + '\n\n' + triples))
 end

 def autocomplete_for_chr
   value = params[:term]
   method = params[:method]
   conditions = ["(chrs.name LIKE ? OR chrs.id = ?) and proj_id = ?",  "%#{value}%", value, @proj.id]
   @chrs = Chr.find(:all, :conditions => conditions, :limit => 35, :order => 'chrs.name')
   render :json => autocomplete_result(:entries => @chrs, :method => method)
 end


end
