namespace :mx do
  namespace :develop do
    task :controller_methods => [:environment] do
  
     CRUD = [ 'index', 'create', 'new', 'edit', 'show',  'update', 'destroy'] 

      # Code ripped right from http://snippets.dzone.com/posts/show/4792 
      controllers = Dir.new("#{RAILS_ROOT}/app/controllers").entries 
      controllers.each do |controller|
        next if controller =~ /\~/ || controller =~ /\.swp/ || controller =~ /base/i # ignore vim temp files
        if controller =~ /_controller/ 
          cont = controller.camelize.gsub(".rb","")
          puts cont
          (eval("#{cont}.new.methods") - 
           ApplicationController.methods - 
           Object.methods - ApplicationController.new.methods).sort.each {|met| 
            puts "\t#{met}" if !CRUD.include?(met.to_s)
          }
        end
      end

     # Code ripped right from http://snippets.dzone.com/posts/show/4792 
      controllers = Dir.new("#{RAILS_ROOT}/app/controllers/public").entries
      controllers.each do |controller|
        next if controller =~ /\~/ || controller =~ /\.swp/ || controller =~ /base/i # ignore vim temp files
        if controller =~ /_controller/ 
          cont = 'Public::' + controller.camelize.gsub(".rb","")
          puts cont
          (eval("#{cont}.new.methods") - 
           ApplicationController.methods - 
           Object.methods - ApplicationController.new.methods).sort.each {|met| 
            puts "\t#{met}" if !CRUD.include?(met.to_s)
          }
        end
      end




    end
  end
end

