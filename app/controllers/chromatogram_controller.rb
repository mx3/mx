class ChromatogramController < ApplicationController
  verify :method => :post, :only => [ :destroy, :create, :update ],
    :redirect_to => { :action => :list }
   
  def index
    list
    render :action => 'list'
  end

  def list
     @chromatogram_pages, @chromatograms = paginate :chromatograms,  :per_page => 20, :conditions => "(proj_id = #{@proj.id})"
  end

  def show
    @chromatogram = Chromatogram.find(params[:id])
     @seqs = @chromatogram.seqs
  end

  def new
    @chromatogram = Chromatogram.new
    @target = 'edit' # whether or not we show the file 
    @seqs = [] 
  end

  def create

    @chromatogram = Chromatogram.new(params[:chromatogram])  
    
    begin
      Chromatogram.transaction do 
        @chromatogram.save!
        
        if !params[:seq][:seq_id].empty? # attach this Chromatogram to a Seq if requested
          if @seq = Seq.find(params[:seqs_chromatograms][:seq_id])
            @seq.chromatograms << @chromatogram 
          end
        end 

        flash[:notice] = 'Chromatogram was successfully created.'
      end

    rescue ActiveRecord::RecordInvalid => e
      flash[:notice] = "Record not saved: #{e}"
      @target = 'create'
      render :action => 'new' and return 
    end
    
    @seqs = @chromatogram.seqs
    render :action => :show
  end

  def edit
    @chromatogram = Chromatogram.find(params[:id])
    @target = 'edit' # whether or not we show the file
    @seqs = @chromatogram.seqs
  end

  def update
    @chromatogram = Chromatogram.find(params[:id])
    @seqs = @chromatogram.seqs
    
    if @chromatogram.update_attributes(params[:chromatogram]) ## this is wonkified
      flash[:notice] = 'Chromatogram was successfully updated.'

    unless params[:seqs_chromatograms][:seq_id] == ""
      @seq = Seq.find(params[:seqs_chromatograms][:seq_id])

      @seq.chromatograms<<(@chromatogram) ## test for success 
    end
    
      redirect_to :action => 'show', :id => @chromatogram
    else
      flash[:notice] = 'Chromatogram was NOT successfully updated.'
      render :action => 'edit'
    end
  end
 
  def destroy
    Chromatogram.find(params[:id]).destroy
    redirect_to :action => 'list' 
  end
  
  # filename is a kludge 
  def return_chromatograph_file
    @chromatogram = Chromatogram.find(params[:id])
    send_file("public/" + @chromatogram.public_filename, :filename => @chromatogram.filename, :disposition => 'attachment', :stream => false) 
  end
  
end

