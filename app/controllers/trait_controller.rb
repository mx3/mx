# Search for 'trait' in layout_helper.rb and navigation helper to see how I configured the tabs. 
# Ultimately we'll write some code that hides the rest of the world (you can select tabs to show in settings at present)
# http://127.0.0.1:3000/projects/12/trait

# There is no Trait model in the database.
# These actions are specific to the trait-based data-capture workflow
# being developed in conjunection with NESCent projects.
class TraitController < ApplicationController
  respond_to :html, :js
  
  def index
  end

  def new
    @otu = Otu.new
    @ce = Ce.new
  #@otu_groups = @proj.otu_groups
  end

  def create
    @otu = Otu.new(params[:otu])
    @ce = Ce.new(params[:ce])
    @ce.save
    @otu[:source_ce_id] = @ce.id
    @otu[:name] = @otu.create_otu_name(@otu.taxon_name_id, @otu.source_ref_id, @ce.id)
    if @otu.save
      notice "Created a new OTU."
      # @show = ['default'] # see /app/views/shared/layout
      # render :action => :show
      render :action => :code_otu, :id => @otu and return
    else
      notice 'Problem creating the OTU!'
      # @otu_groups = @proj.otu_groups
      render :action => :enter_from_ref and return
    end
  end

  # Match these methods to Cory's stories
  def enter_from_ref
    @otu = Otu.new
    @ce = Ce.new
  end

  def browse_data
  end

  def code_otu
    @otu = Otu.find(params[:id])
  end

  def show_codings
    @mxes = @otu.mxes
    @codings = []
    if params[:show_all]
      @uniques = Coding.unique_for_otu(@otu)
    @codings = @otu.codings.ordered_by_chr
    end

    @no_right_col = true
    render :action => 'code_otu'
  end

  
end
