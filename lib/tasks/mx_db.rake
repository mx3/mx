require 'rake'
require 'benchmark'
# require 'ruby-debug' (see READMEtasks.rdoc)

namespace :mx do
  namespace :db do
    desc "Dump the data to an SQL file"

    task :dump_data => :environment do
      abcs = ActiveRecord::Base.configurations
      @file_name = "#{DATA_DIR}/" + Time.now.strftime("%Y_%m_%d_%H%M%S") + ".sql"
 
     # puts "Wiping sessions" 
     # ActiveRecord::SessionStore::Session.destroy_all

      puts "Dumping data"
     
      # Kind of lame to resort to shell expansion (``), but mysqldump seemed the best way to go. Need to have mysqldump in your path
      # NOTE: we no longer dump the schema_migrations because it is regenerated on db:migrate, if you need to keep track of this do it manually
      puts Benchmark.measure { dump_result = `mysqldump --ignore-table=#{abcs[ENV['RAILS_ENV']]['database']}.schema_migrations --add-locks --complete-insert --no-create-db --no-create-info --skip-add-drop-table --skip-create-options --skip-disable-keys --skip-quick --user=#{abcs[ENV['RAILS_ENV']]['username']} --password=#{abcs[ENV['RAILS_ENV']]['password']} #{abcs[ENV['RAILS_ENV']]['database']} > #{@file_name}` }
 
      # did we write a file?
      raise "Failed to create dump file" unless File.exists?(@file_name)
    end

    def db_reload(dumpfile)
      abcs = ActiveRecord::Base.configurations
      raise "Unable to read from file '#{dumpfile}'" if not File.readable?(dumpfile)
      puts "Dropping database"
      puts Benchmark.measure { table_drop = ActiveRecord::Base.connection.recreate_database(abcs[ENV['RAILS_ENV']]["database"])  } # MySQL ONLY! see (http://errtheblog.com/posts/2-rake-remigrate ) for other hints
      puts "Creating tables"
      ActiveRecord::Base.connection.reconnect!
      puts Benchmark.measure { table_create = Rake::Task["db:migrate"].invoke } 
      puts "Loading data"
      puts Benchmark.measure { data_reload =  `mysql --user=#{abcs[ENV['RAILS_ENV']]['username']} --password=#{abcs[ENV['RAILS_ENV']]['password']} #{abcs[ENV['RAILS_ENV']]['database']} < #{dumpfile}` }
    end

    desc "Dump the data, recreate the tables and reload the data"
    task :reload => :dump_data do
      db_reload(@file_name)
    end

    desc "Dump the data as a backup, then restore the db from the specified file."
    task :restore => :dump_data do
      raise "Specify a dump file: rake file=myfile.sql restore" if not ENV["file"]
      db_reload("#{DATA_DIR}/" + ENV["file"])  
    end

    desc "Restore from youngest dump file. Handy!"
    task :restore_last => [:find_last, :restore]

    # assumes you have nothing but data dumps in /dumps
    task :find_last => :environment do
	  # should really be based on create time NOT the bottom of the DIR
      ENV["file"] = Dir.entries(DATA_DIR).last
      raise "Bad dump file: #{ENV["file"]}" unless ENV["file"][-4,4] == ".sql"
    end
  end
end
