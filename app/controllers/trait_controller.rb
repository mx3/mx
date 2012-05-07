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

  # Match these methods to Cory's stories
  def enter_from_ref
    session['trait_new_otu'] = {'ref_id' =>  nil, 'taxon_name_id' => nil, 'ce_id' => nil}
    render :action => '/trait/enter_from_ref/enter_from_ref'
  end

  # Called via AJAX callbacks for each submit of the enter_from_ref path
  def otu_compiler
   # see otu_compiler.js.erb for the logic 
   session['trait_new_otu'][params[:assign]] = params[:obj][:id]
   @ref = Ref.find(session['trait_new_otu']['ref_id'] ) if !session['trait_new_otu']['ref_id'].nil?
   @ce = Ce.find(session['trait_new_otu']['ce_id'] ) if !session['trait_new_otu']['ce_id'].nil?
   @taxon_name = TaxonName.find(session['trait_new_otu']['taxon_name_id'] ) if !session['trait_new_otu']['taxon_name_id'].nil?
   render :action => 'trait/enter_from_ref/otu_compiler'
  end

  def create_otu
    @otu = Otu.new(params[:otu])
    @otu.name = Trait.trait_otu_name(@otu.ref, @otu.taxon_name, @otu.ce)

    if @otu.save
      notice "Created a new OTU."

      # Sandy - I suggest we set a session flag here like session['trait-mode'] = true, then add return logic into the matrix
      # based views in matrix_coding or browse coding etc.  

      redirect_to :action => :matrix_coding, :controller => :mxes, :otu_id => @otu.id, :id => @proj.mxes.first.id and return

      # We could also drop into one-click mode from here (e.g. http://127.0.0.1:3000/projects/12/mxes/301/code/row/0/6521/3857),
      # see Matrices->show->otus->code for how the intial route is generated.
      # Or- you might want a intermediate "staging" page that says asks you how you want to code this new OTU

    else
      notice 'Problem creating the OTU!'
      render :action => '/trait/enter_from_ref/enter_from_ref' and return
    end
  end

  def new_ref
    @ref = Ref.new
  end

  # Hit from AJAX only, see save_new_ref.js.erb for followup
  def save_new_ref
    if params[:ref][:author].blank? || params[:ref][:year].blank?
      notice "Reference not created, you most provide an author and a year."
    else

    @ref = Ref.new(params[:ref])
      if @ref.save
        @proj.refs << @ref  # make sure the ref is in this project as well
        notice "Created a new Reference."
      else
        notice 'Problem creating the Reference!'
      end
    end
  end

  def new_ce
    @ce = Ce.new
  end

  def save_new_ce
    @ce = Ce.new(params[:ce])
    if @ce.save!
      notice 'Created a new study/population.'
    else
      notice 'Problem creating a new study/population'
    end
  end

  def new_taxon_name
    @taxon_name = TaxonName.new
  end

  # TODO: This hasn't been tested by MJY
  def save_new_taxon_name
    @taxon_name = TaxonName.create_new(:taxon_name => params[:taxon_name], :person => session[:person])
    begin 
      TaxonName.transaction do
      if @taxon_name.errors.size > 0
        raise @taxon_name.errors
      end

      @taxon_name.save!

      if @taxon_name.errors.size > 0
        notice = @taxon_name.errors.size + ' errors.' 
        render :action => :new_taxon_name
      else
        notice = 'Species Name was successfully created.'
        redirect_to :action => :enter_from_ref and return
      end
    end

    rescue  Exception => e 
      notice = e.message 
      render :action => :new_taxon_name and return
    end
  end

 # Coding based (see comments above)

 #def code_otu
 #  @otu = Otu.find(params[:id])
 #end

 #def show_codings
 #  @mxes = @otu.mxes
 #  @codings = []
 #  if params[:show_all]
 #    @uniques = Coding.unique_for_otu(@otu)
 #  @codings = @otu.codings.ordered_by_chr
 #  end

 #  @no_right_col = true
 #  render :action => 'code_otu'
 #end

 #def browse_data
 #end

end
