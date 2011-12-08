class SeqsController < ApplicationController

  layout "layouts/application",  :except => :seqs_as_fasta_file
  layout "layouts/application",  :except => :seqs_as_oneline_file

  def index
    list
    render :action => 'list'
  end

  def list  
    @seqs = Seq.by_proj(@proj).page(params[:page]).per(30).order('updated_on DESC')
  end

  def show
    id = params[:seq][:id] if params[:seq] # for autocomplete/ajax picker use 
    id ||= params[:id]
    @seq = Seq.find(id)
    @chromatograms = @seq.chromatograms
    @show = ['default']
  end

  def new
    @seq = Seq.new
  end

  def new_from_table
    @seq = Seq.new()
    @seq.gene_id = params[:gene_id]
    @seq.otu_id = params[:otu_id]
    @seq.save
    flash[:notice] = "Created new sequence."
    render :action => :edit
  end

  def create  
    @seq = Seq.new(params[:seq])
    if @seq.save
      flash[:notice] = 'Sequence was successfully created.'
      redirect_to(:action => :show, :id => @seq)
    else
      flash[:notice] = 'Not saved!'
      render :action => :new
    end
  end

  def create_multiple # trys to add seqs for all members of an otu_group (run elsewhere?)
    @p, @f = Seq.create_multiple(params[:multi_seq])
    if @p
      flash[:notice] = 'Added ' + @p.to_s + ", and failed to add (most likely the otu/gene combo already exists) " + @f.to_s + ', sequences.' 
    else 
      flash[:notice] = "None added, possible error with passed parameters."
    end
    redirect_to :action => :list
  end

  def edit
    @seq = Seq.find(params[:id])
  end

  def update
    @seq = Seq.find(params[:id])
    if @seq.update_attributes(params[:seq])
      flash[:notice] = 'Seq was successfully updated.'
      redirect_to :action => 'show', :id => @seq
    else
      render :action => :edit
    end
  end

  def destroy
    Seq.find(params[:id]).destroy
    redirect_to :action => :list
  end

  def list_by_scope
    if params[:arg]
      @seqs = @proj.seqs.send(params[:scope],params[:arg])
    else
      @seqs = @proj.seqs.send(params[:scope])
    end 
    @list_title = "Sequences #{params[:scope].humanize.downcase}" 
    render :action => :list_simple
  end

  def summarize
    if request.post? 
      @otus = []
      @genes = []
      if search = Seq.summary_grid(params[:view])
        @genes = search[:genes]
        @otus = search[:otus]
      end
    end

    respond_to do |format|
      format.html {
        if request.post? 
          if @genes.size == 0 || @otus.size == 0
            flash[:notice] = "No genes or OTUs returned!"
            render :action => :summarize and return
          end

          case params[:report_type].to_sym
          when :extracts_by_gene_colored
            flash[:notice] = '<strong style="color:red;">That report not available as a file.</strong>'
            render :action => :summarize and return 

          when :extracts_by_gene_simple
            f = render_to_string(:partial => "seq/reports/#{params[:report_type].to_s}", :locals => {:genes => @genes, :extracts => @extracts}, :layout => false)
            send_data(f, :filename => 'mx_extract_summary.tab', :type => "application/rtf", :disposition => "attachment")
          end and return
        end 
      }

      format.js {
        if @otus.size == 0 || @genes.size == 0
          render :update do |page|
            page.replace_html :result, :text => '<em style="color: red;">No results returned, you may need to choose OTUs or genes.</em>'
          end and return
        end 

      render :update do |page|
        page.replace_html :result, :partial => "/seq/reports/screen/#{params[:report_type].to_s}", :locals => {:genes => @genes, :otus => @otus}
      end and return

      # something went horribly wrong, 
      #render :update do |page|
      #  page.replace_html :result, :text => '<strong>Controller misconfigured, contact admin.</strong>'
      #end and return
      }
    end

  end

  def view_query  ## call summarize or some such???
    # check that both a groups have been selected
    if  params[:view][:otu_group_id].empty? || params[:view][:gene_group_id].empty? # params[:view][:all_otus].empty? && 
      flash[:notice] = 'Include both a gene group and a OTU group or select All OTUs'
      @target = ''
      render :action => :views and return
    end

    @result = Seq.summary_grid(params)

    if !@result 
      flash[:notice] = 'One (or both) of your gene or OTU groups is empty!'
      @target = ''
      render :action => :views and return
    end

    @report_type = params[:report][:type] if params[:report]
    @report_type ||= 'report_grid_summary'

    render :action => :views, :otu_group_id => params[:view][:otu_group_id] 
  end

  ## lots of redundancy for file output, should just parameterize
  def seqs_as_fasta_file
    @f = Seq.fasta_file(params)
    if @f
      send_data(@f, :filename => 'mx_matrix.fas', :type => "application/rtf", :disposition => "attachment")
    else
      flash[:notice] = "Couldn't generate the file, make sure you select valid options."
      render :action => :views and return
    end
  end

  def seqs_as_oneline
    @f = Seq.one_line_file(params)
    if @f
      send_data(@f, :filename => 'mx_matrix.txt', :type => "application/rtf", :disposition => "attachment")
    else
      flash[:notice] = "Couldn't generate the file, make sure you select valid options."
      render :action => :views and return
    end
  end

  def seqs_as_nexus
    @f = Seq.nexus_file(params)
    if @f
      send_data(@f, :filename => 'mx_matrix.nex', :type => "application/rtf", :disposition => "attachment")
    else
      flash[:notice] = "Couldn't generate the file, make sure you select valid options."
      render :action => :views and return
    end 
  end

  def seqs_from_FASTA
  end

  def verify_seqs_from_FASTA
    @seqs = Seq.batch_load_FASTA(:file => params[:file])
    if @seqs.nil?
      flash[:notice] = "An error occured. Make sure to select a FASTA formatted file. Check the format of the line endings in your file, they must be unix or dos format, not Mac." 
      render :action => :seqs_from_FASTA and return 
    end 
    flash[:notice] = "Succesfully read file."
  end

  def _batch_add_FASTA 
    if r =  Seq.add_FASTA_after_verify(params)
      flash[:notice] = "Added #{r.size} sequences."
      redirect_to :action => :list, :controller => :seqs and return
    else
      flash[:notice] = "Problem adding sequences!"
      redirect_to :action =>  :verify_seqs_from_FASTA and return
    end
  end

  def auto_complete_for_seq
    value = params[:term]
    method = params[:method]
    if value.nil?
      redirect_to(:action => 'index', :controller => 'ontology') and return
    else
      @seqs = Seq.find_for_auto_complete(value, @proj.id)
    end
    render :json => Json::format_for_autocomplete_with_display_name(:entries => @seqs, :method => params[:method])
  end

  # def blast
  # remote_blast_factory = Bio::Blast.remote('blastn', 'SWISS', '-e 0.0001', 'genomenet')

  # report = remote_blast_factory.query(params[:seq])
  # render :update do |page|
  #  page.replace_html :result, debug(report)
  # end and return
  # end

end
