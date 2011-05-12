namespace :mx do
  namespace :db do
    desc "(not working yet)" # Setup databases and permissions for a new installation of mx ."
    task :setup => [:grants, :build_databases, :environment, :root_taxon_name] do
      
    # TODO: need additional tasks?
      # rake reload

    #
    # -- db setup for mx, run as root
    #
    # create database mx_development;
    # create database mx_test;
    # create database mx_production;
    #

    end
    
    task :grants do
      puts "root password for mysql:"
      mypass = gets.chomp
      puts "desired password for the mx user:"
      mxpass = gets.chomp
      puts mypass
      puts mxpass
      
      # TODO: password for development machines?
      
    # grant usage on *.* to 'mx'@'localhost' identified by 'change-this-password';
    #
    # grant all on mx_production.* to 'mx'@'localhost';
    # grant all on mx_development.* to 'mx'@'localhost';
    # grant all on mx_test.* to 'mx'@'localhost';
    end
    
    task :build_databases do

    end

    task :root_taxon_name do
      puts "enter a taxon name for the root node of the taxonomic heirarchy (e.g. 'root'):"
      root_node = gets.chomp
      root_node ||= 'root'
      # just run a mysql insert, include the "display_name" field
    end
  end
end

