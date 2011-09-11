class MultikeyController < ApplicationController
  before_filter :find_key, :except => [:reset,:_cycle_elim_otu_txt_choices, :_cycle_remn_otu_txt_choices, :_cycle_elim_chr_txt_choices, :_cycle_remn_chr_txt_choices,  :_popup_figs_for_state, :_close_popup_figs, :list, :add_state, :remove_state, :return_otu, :return_chr, :choose_otu, :_update_otu_for_compare, :_popup_figs_for_state, :_popup_figs_for_chr, :_close_popup_figs, :_show_figures_for_chr]
  before_filter :set_key, :only => [:add_state, :remove_state, :return_otu, :return_chr, :choose_otu, :_update_otu_for_compare, :_popup_figs_for_state, :_popup_figs_for_chr,:_cycle_remn_chr_txt_choices, :_cycle_elim_chr_txt_choices,:_cycle_remn_otu_txt_choices,:_cycle_elim_otu_txt_choices, :_show_figures_for_chr]
  before_filter :content, :only => [:show, :show_compare, :show_otu_by_chr, :show_default, :show_chosen_figures, :show_remaining_figures, :show_chosen_states, :show_tags] 

  def index
    list
    render :action => 'list'
  end

  def list
    session[:multikey] = nil
    @multikeys = @proj.multikeys
  end

  def show
  end

  def show_compare
    @mk.set_view('compare')
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
    @mk.add_states([params[:id].to_i ])
    redirect_to(:action => 'show_default', :id => @mk.MX_ID) and return
  end

  def remove_state
    @mk.remove_states([params[:id].to_i])
    redirect_to(:action => 'show_default', :id => @mk.MX_ID)
  end

  def choose_otu
    # add all the unique states for that OTU, essentially ending the key
    @mk.choose_otu(params[:id].to_i)
    redirect_to(:action => 'show_default', :id => @mk.MX_ID)
  end

  def return_otu
    # remove all the unique states for that OTU
    @mk.return_otu(params[:id].to_i)
    redirect_to(:action => 'show_default', :id => @mk.MX_ID)
  end

  def return_chr
    # remove all the unique states for that OTU
    @mk.return_chr(params[:id].to_i)
    redirect_to(:action => 'show_default', :id => @mk.MX_ID)
  end

  def reset
    session[:multikey] = nil
    @mk = Multikey.new(params[:id])
    redirect_to(:action => 'show_default', :id => @mk.MX_ID)
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
    render(:layout => false, :partial => "figures"  ) 
  end

  # not implemented yet
  def _cycle_remaining_figures_by_chr
  end

  # this is a little bad because it doesn't access the state space of the multikey, but 
  # rather a state directly.
  def _popup_figs_for_state
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
 
  # make this RJS inline 
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
  
  # major kludge
  def _update_otu_for_compare
    # ugh, becase we have proj_id in there too we have to do something sneaky to ensure we get our value (or write a route silly)
    render(:layout => false, :partial => "otu_and_states", :collection => [Otu.find(params.keys.sort[0].to_i)]  )
  end

  private

  # hit on before_filter
  # assumes the key is in the session variable 
  # this should only be hit through the before_filter 
  # slightly redundant with find_key, but NOT COMPLETELY SO- allows simpler set urls
  def set_key
    @mk = session[:multikey]
    true
  end

  # hit on before_filter
  def find_key
    begin
      if session[:multikey] && (params[:id].to_i == session[:multikey].MX_ID.to_i)
        # do nothing
      else
        session[:multikey] = nil
        session[:multikey] = Multikey.new(params[:id]) 
      end 

    @mk = session[:multikey]
    # windows are default set 
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
