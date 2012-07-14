class ChrGroupsController < ApplicationController

  def index
    list
    render :action => :list
  end

  def list
    @chr_groups = @proj.chr_groups
  end

  def show
    @chr_group = ChrGroup.find(params[:id])
    @chrs_in = @chr_group.chr_groups_chrs(:include => :chr)
    @no_right_col = true
    @show = ['default']
  end

  def show_detailed
    @chr_group = ChrGroup.find(params[:id])
    @chrs  = @chr_group.chrs
    @no_right_col = true
    render :action => 'show'
  end

  def show_content_mapping
    @chr_group = ChrGroup.find(params[:id], :include => [:content_type, [:chrs => :chr_states]])
    @no_right_col = true
    @l =  Linker.new(:link_url_base => self.request.host, :proj_id => @proj.ontology_id_to_use, :incoming_text => @chr_group.all_chr_txt, :adjacent_words_to_fuse => 5)
    render :action => 'show'
  end

  def new
    @chr_group = ChrGroup.new
    render :action => :new
  end

  def create
    @chr_group = ChrGroup.new(params[:chr_group])
    if @chr_group.save
     flash[:notice] = 'ChrGroup was successfully created.'
      redirect_to :action => :list
    else
      render :action => :edit
    end
  end

  def edit
    @chr_group = ChrGroup.find(params[:id])
  end

  def update
    @chr_group = ChrGroup.find(params[:id])
    if @chr_group.update_attributes(params[:chr_group])
      flash[:notice] = 'ChrGroup was successfully updated.'
      redirect_to :action => :show, :id => @chr_group.id
    else
      render :action => :edit
    end
  end

  def destroy
    ChrGroup.find(params[:id]).destroy
    redirect_to :action => :list
  end

  def add_chr
    if @chr_group = ChrGroup.find(params[:chr_group][:id])
      if c = Chr.find(params[:chr][:id])
        if @chr_group.add_chr(c) # !!! NOT <<,  previous membership is checked/matrices checked as well
          flash[:notice] = "Added a character to '#{@chr_group.display_name}'."
        else
         flash[:notice] = "Problem adding character to group, perhaps it is in the list already?"
        end
      else
        flash[:notice] = "Character not found, did you select from the list?"
      end
    else
      flash[:notice] = "Character group not found."
    end
   redirect_to :action => :show, :id => @chr_group.id
  end

  def sort_chrs
    params[:chr_groups_chr].each_with_index do |id, index|
      ChrGroupsChr.update_all(['position=?', index+1], ['id=?', id])
    end
    notice 'Updated character order.'
    render :nothing => true
  end

  def remove_chr
    @chr_group = ChrGroup.find(params[:id])
    @chr_group.remove_chr(Chr.find(params[:chr_id]))
    notice "Removed Chr"
    redirect_to :back # (:controller => :chr_groups, :id  => @chr_group.id, :action => :show) and return
  end

  def make_default
    session['group_ids']['chr'] = params[:id]
    redirect_to :action => :list
  end

  def clear_default
    session['group_ids']['chr'] = nil if session['group_ids']
    redirect_to :action => :list
  end

  def move
    @proj.chr_groups.find(params[:id]).send(params[:move])
    flash[:notice] = 'moved'
    redirect_to :action => :list
  end

   def reset_position
    i = 1
      for o in @proj.chr_groups
        o.position = i
        o.update
        i += 1
      end
      flash[:notice] = 'order reset'
    redirect_to :action => :list
   end

  def chrs_without_groups
    @chrs = @proj.chrs.without_groups
  end

  def assign_chrs_without_groups
    @chr_group = ChrGroup.find(params[:id])
  end

  def add_ungrouped_characters
    redirect_to(:action => :chrs_without_groups) and return if (params[:cg].blank? || params[:cg][:id].blank?)
    ChrGroup.find(params[:cg][:id]).add_ungrouped_chrs
    redirect_to :action => :show, :id => params[:cg][:id]
  end

  def auto_complete_for_chr_groups
    @chr_groups = ChrGroup.auto_complete_search_result(params.merge!(:proj_id => @proj.id))
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @chr_groups, :method => params[:method])
  end

end
