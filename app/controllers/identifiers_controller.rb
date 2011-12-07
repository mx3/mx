class IdentifiersController < ApplicationController
  
  def destroy 
    Identifier.find(params[:id]).destroy
    redirect_to :back
  end
 end
