class Public::BaseController < ApplicationController
  # All shared public controllers should be of subclasses of this class
  # IF YOU ALTER THIS FILE YOU MUST RESTART THE SERVER- why, I dunno, but you do
 
  # layout proc { |controller| controller.request.xhr? ? 'popup' : 'application'  } 

  layout :conditional
  
  def conditional
    
    if @proj && @proj.site && Rails.env == "production"
      "/public/site/#{@proj.site}/layout" 
    else # site specific layouts don't exist in the core application, so check where we're developing from
      if @proj && @proj.site
        layout_exists = false
        self.view_paths.each do |path|
          if File.readable?("public/site/#{@proj.site}/layout.html.erb")
            
            layout_exists = true  
          end
        end          
        layout_exists  ? "public/site/#{@proj.site}/layout" : "stub"
      end
    end
  end

end


