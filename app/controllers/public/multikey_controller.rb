class Public::MultikeyController < Public::BaseController

  # requires Public::ClaveController to configured as public in Proj->settings

  before_filter :find_key, :except => [:reset,:_cycle_elim_otu_txt_choices, :_cycle_remn_otu_txt_choices, :_cycle_elim_chr_txt_choices, :_cycle_remn_chr_txt_choices, :_popup_figs_for_state, :_close_popup_figs, :list, :add_state, :remove_state, :return_otu, :return_chr, :choose_otu, :_update_otu_for_compare, :_popup_figs_for_state, :_popup_figs_for_chr, :_close_popup_figs, :_show_figures_for_chr]
  before_filter :set_key, :only => [:add_state, :remove_state, :return_otu, :return_chr, :choose_otu, :_update_otu_for_compare, :_popup_figs_for_state, :_popup_figs_for_chr, :_cycle_remn_chr_txt_choices, :_cycle_elim_chr_txt_choices,:_cycle_remn_otu_txt_choices,:_cycle_elim_otu_txt_choices, :_show_figures_for_chr]
  before_filter :content, :only => [:show, :show_compare, :show_otu_by_chr, :show_default, :show_chosen_figures, :show_remaining_figures, :show_chosen_states, :show_tags] 
  before_filter :check_for_bot_formatted_links_and_return_404s, :only => [:add_state, :remove_state, :return_otu, :return_chr, :choose_otu, :_cycle_remn_chr_txt_choices, :_cycle_elim_chr_txt_choices,:_cycle_elim_otu_txt_choices, :_cycle_remn_otu_txt_choices, :_show_figures_for_chr]
 
  # route this ultimately?
  def check_for_bot_formatted_links_and_return_404s
    render :file => "#{Rails.root}/public/404.html", :status => :not_found and return if @mk.nil?
  end

  def index
    list and return
  end

  def list
    # public keys are now all listed through clave/list (both bifurcating and multikey
    redirect_to :action => :list, :controller => :claves
  end

  def show
  end

  def show_compare
    @mk.set_view('compare')
    render(:action => 'show', :id => @mk.MX_ID)
  end

  def show_tags
    @mk.set_view('tags')
    # configure to find all tags for Chr, OTU, ChrState, Codings
    @tags = @mk.remaining_tags
    render(:action => 'show', :id => @mk.MX_ID)
  end
  
  def show_otu_by_chr
    @mk.set_view('otu_by_chr')
    render(:action => 'show', :id => @mk.MX_ID)
  end

  def show_default
    @mk.set_view('default')
    render(:action => 'show', :id => @mk.MX_ID)
  end

  def show_chosen_figures
    @mk.set_view('chosen_figures')
    @figures = @mk.chosen_figures
    render(:action => 'show', :id => @mk.MX_ID)
  end

  def show_remaining_figures
    @mk.set_view('remaining_figures')
    @figures = @mk.remaining_figures
    render(:action => 'show', :id => @mk.MX_ID)
  end

  def show_chosen_states
    @mk.set_view('chosen_states')
    render(:action => 'show', :id => @mk.MX_ID)
  end
  
  def add_state
    if @mk.nil? # temp bot solution
      render(:text => '404', :status => 404)  and return
    end
    @mk.add_states([ params[:id].to_i ])
    redirect_to(:action => 'show', :id => @mk.MX_ID)
  end

  def remove_state
    @mk.remove_states([params[:id].to_i])
    redirect_to(:action => 'show', :id => @mk.MX_ID)
  end

  def choose_otu
    # add all the unique states for that OTU, essentially ending the key
    @mk.choose_otu(params[:id].to_i)
    redirect_to(:action => 'show', :id => @mk.MX_ID)
  end

  def return_otu
    # remove all the unique states for that OTU
    @mk.return_otu(params[:id].to_i)
    redirect_to(:action => 'show', :id => @mk.MX_ID)
  end

  def return_chr
    # remove all the unique states for that OTU
    @mk.return_chr(params[:id].to_i)
    redirect_to(:action => 'show', :id => @mk.MX_ID)
  end

  def reset
    session[:multikey] = nil
    @mk = Multikey.new(params[:id])
    redirect_to(:action => 'show', :id => @mk.MX_ID)
  end

  # ajax related
  def _cycle_remn_chr_txt_choices
    @mk.slide_window('chr_remn', params[:direction])
    @chrs_remn  = @mk.remaining_chrs
    render(:layout => false, :partial => params[:partial_to_render], :collection => @chrs_remn)
  end

  def _cycle_elim_chr_txt_choices
    @mk.slide_window('chr_elim', params[:direction])
    @chrs_elim  = @mk.eliminated_chrs
    render(:layout => false, :partial => "c", :collection => @chrs_elim)
  end

  # check
  def _cycle_remn_otu_txt_choices
    @mk.slide_window('otu_remn', params[:direction])
    @otus_remn  = @mk.remaining_otus
    render(:layout => false, :partial => "o", :collection => @otus_remn, :locals => {'action' => 'choose_otu', 'link_txt' => ''})
  end

  def _cycle_elim_otu_txt_choices
    @mk.slide_window('otu_elim', params[:direction])
    @otus_elim = @mk.eliminated_otus
    render(:layout => false, :partial => "o", :collection => @otus_elim, :locals => {'action' => 'return_otu', 'link_txt' => 'R'})
  end

  def _show_figures_for_chr
    @figures = Figure.find(@mk.figures_by_chr(params[:id]))
    @chr = Chr.find(params[:id])
    render(:layout => false, :partial => "figures") # doesn't need view?)
  end

  # this is a little bad because it doesn't access the state space of the multikey, but 
  # rather a state directly.
  def _popup_figs_for_state
    redirect_to :action => :list and return if not session[:multikey]
    @cs = ChrState.find(params[:id])
    respond_to do |format|
      format.html {}
      format.js {
        render :update do |page|
          page.replace_html :figs_holder, :partial => 'popup_figs_for_state'
        end and return
      }
    end
  end
  
  # this is bad too, for the same reasons as above (DRY this)
  def _popup_figs_for_chr
    redirect_to :action => :list and return if !session[:multikey] # why is this here?
    @chr_states = Chr.find(params[:id]).chr_states
    respond_to do |format|
      format.html {}
    format.js {
      render :update do |page|
        page.replace_html :figs_holder, :partial => 'popup_figs_for_chr'
        end and return
      }
    end
  end

  # TODO: not a server call
  def _close_popup_figs  
    respond_to do |format|
      format.html {}
      format.js {
      render :update do |page|
        page.replace_html :figs_holder, ''
        end and return
      }
    end
  end

 ## not implemented yet
 #def _cycle_remaining_figures_by_chr
 #  @mk = find_key
 #end

  # major kludge
  def _update_otu_for_compare
    # ugh, becase we have proj_id in there too we have to do something sneaky to ensure we get our value (or write a route silly)
    render(:layout => false, :partial => "otu_and_states", :collection => [Otu.find(params.keys.sort[0].to_i)]  )
  end

  private
 
# hit on before_filter
  # assumes the key is in the session variable 
  # this should only be hit through the before_filter 
  def set_key
    @mk = session[:multikey]
    true
  end

  # hit on before_filter
  # assumes a project_id is passed

  def find_key
    begin
      if session[:multikey] && (params[:id].to_i == session[:multikey].MX_ID.to_i)
        # do nothing
      else
        session[:multikey] = nil
        session[:multikey] = Multikey.new(params[:id]) 
      end 

      # windows are default set
      @mk = session[:multikey]
    rescue
      flash[:notice] = "No such key."
      redirect_to :action => :list and return
    end

    true # it's a filter!
  end

  def content
    @chrs_elim = @mk.eliminated_chrs # note these is a windowed set, not the full set
    @chrs_remn  = @mk.remaining_chrs
    @otus_elim  = @mk.eliminated_otus
    @otus_remn = @mk.remaining_otus
    
    # we can get this elsewhere, but use .size in more than one place, so set it as a constant
    @size_otus_elim = @mk.otus_eliminated.size
    @size_otus_remn = @mk.otus_remaining.size
    @size_chrs_remn = @mk.chrs_remaining.size
    @size_chrs_elim = @mk.chrs_eliminated.size
    
    @no_right_col = true if @mk.view == 'compare'
    true # it's a filter
  end

end
