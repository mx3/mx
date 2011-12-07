class ChrStatesController < ApplicationController
  # used only in redirects of tags/figures

  in_place_edit_for :chr_state, :notes

  def index
    redirect_to :action => :index, :controller => :chrs
  end

  def show
    redirect_to :action => :show, :controller => :chrs, :id => ChrState.find(params[:id]).chr_id
  end

  def show_figures
    @chr_state = ChrState.find(params[:id])
    redirect_to :action => :show, :controller => :chrs, :id => @chr_state.chr_id
  end 

  def _in_place_notes_update
    c = ChrState.find(params[:id])
    c.notes = params[:value]
    if c.save
      render :text => c.notes
    else
      render :text => '<span style="color: red;">Validation failed, record not updated.</span>'
    end
  end
  
  def destroy_phenotype
    chr_state = ChrState.find(params[:id])
    chr_state.phenotype = nil
    chr_state.save
    redirect_to :controller => :chrs, :action => :show, :id => chr_state.chr_id
  end

end
