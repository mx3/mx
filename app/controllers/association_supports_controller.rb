class AssociationSupportsController < ApplicationController
  
  def new_ref
    @association = Association.find(params[:association_id])
    @association_support = RefSupport.new
    render :action => 'new'
  end

  def new_specimen
    @association = Association.find(params[:association_id])
    @association_support = SpecimenSupport.new
    render :action => 'new'
  end

  def new_voucher
    @association = Association.find(params[:association_id])
    @association_support = VoucherLotSupport.new
    render :action => 'new'
  end

  def create
    @association = Association.find(params[:association_id])
    params[:association_support].update(:association_id => params[:association_id])

    # i don't really like this, but i don't see a better way to do it
    case params[:association_support]['type']
    when "RefSupport"
      @association_support = RefSupport.new(params[:association_support])
    when "SpecimenSupport"
      @association_support = SpecimenSupport.new(params[:association_support])
    when "VoucherLotSupport"
      @association_support = VoucherLotSupport.new(params[:association_support])
    else
      redirect_to :controller => 'associations', :action => 'show', :id => @association
    end

    if @association_support.save
      flash[:notice] = 'AssociationSupport was successfully created.'
      redirect_to :controller => 'associations', :action => 'show', :id => @association
    else
      flash[:notice] = 'AssociationSupport was NOT successfully created.'
      render :action => 'new'
    end
  end

  def edit
    @association_support = AssociationSupport.find(params[:id])
    @association = Association.find(params[:association_id])
  end

  def update
    @association = Association.find(params[:association_id])
    @association_support = AssociationSupport.find(params[:id])
    if @association_support.update_attributes(params[:association_support])
      flash[:notice] = 'AssociationSupport was successfully updated.'
      redirect_to :controller => 'associations', :action => 'show', :id => @association
    else
      render :action => 'edit'
    end
  end

  def destroy
    @association = Association.find(params[:association_id])
    AssociationSupport.find(params[:id]).destroy
    redirect_to :controller => 'associations', :action => 'show', :id => @association
  end

  # move a support from one relationship to another
  def move
    if @association = Association.find(params[:move][:id]) 
      if @a = AssociationSupport.find(params[:support][:id])
        @a.association_id = @association.id
        if @a.save
          flash[:notice] = "Moved support to association #{@association.id}."
        else
          flash[:notice] = "something went wrong"    
        end
      else
        flash[:notice] = "something went wrong"
      end
      redirect_to :controller => 'associations', :action => 'browse_show', :id => @a.association_id
    end
  end

end
