class IdentifierController < ApplicationController
  verify :method => :post, :only => [ :destroy],
         :redirect_to => { :action => :list } 
  
  def destroy 
    Identifier.find(params[:id]).destroy
    redirect_to :back
  end
 end
