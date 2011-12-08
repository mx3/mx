class ProtocolsController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  def list
    @protocols = Protocol.by_proj(@proj).page(params[:page]).per(20) 
  end

  def show
    @protocol = Protocol.find(params[:id])
    @steps =  @protocol.protocol_steps
  end

  def new
    @protocol = Protocol.new
  end

  def create
    @protocol = Protocol.new(params['protocol'])

    if @protocol.save
      flash[:notice] = 'Protocol was successfully created.'
      redirect_to :action => 'show', :id => @protocol
    else
      render :action => 'new'
    end
  end

  def edit
    @protocol = Protocol.find(params[:id])
    @steps =  @protocol.protocol_steps

  end

  def update
    @protocol = Protocol.find(params[:id])
    if @protocol.update_attributes(params[:protocol])
      flash[:notice] = 'Protocol was successfully updated.'
      redirect_to :action => 'show', :id => @protocol
    else
      render :action => 'edit'
    end
  end

  def destroy
    Protocol.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def add_step # add a protocol step
    @protocol = Protocol.find(params[:id])

    if not params['protocol_step']['description'].empty?
      @step = ProtocolStep.new(params['protocol_step'])
      @step.protocol_id = params[:id]
      if @step.save
        flash[:notice] = 'Protocol step was successfully updated.'
      else
        flash[:notice] = 'Step not added!'
      end
    end    
    redirect_to :action => 'show', :id => params[:id]
  end

  def remove_step # remove a protocol step
    @protocol = Protocol.find(params[:id])
    ProtocolStep.find(params['protocol_step_id']).destroy
    redirect_to :action => 'show', :id => @protocol.id
  end

end
