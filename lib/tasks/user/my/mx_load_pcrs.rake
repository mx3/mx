
require 'tempfile'
require 'csv'

$USAGE = 'Call like: "rake mx:load_pcrs file=<full path> RAILS_ENV=production person=1 project=10"' 

# quick on-time script to load a preformatted table
namespace :mx do
  desc $USAGE

  task :load_pcr_table => [:environment, :project, :person] do

    abort # you souldn't be running this ;)

  # columns are 
  # 0 extract_id
  # 1 fwd_primer_id
  # 2 rev_primer_id
  # 3 protocol_id
  # 4 pcr_id (given)
  # 5 other_id (given)
  # 6 specimen_identifier (given)
  # 7 notes 

   @file = ENV['file']

   if !@file 
     puts "ERROR " + $USAGE
     abort # might be better way to do this
   end

   # 00000 - positve control extract (specimen with 00000) 4579
   # XXXX - specimen with XXXX Derv12a but no extract 4581

   @e_control = Extract.new(:specimen_id => 4579)
   @e_control.save

   @e_derv = Extract.new(:specimen_id => 4581)
   @e_derv.save

    pcrs = get_csv(@file)
    pcrs.shift # first row is headers

    begin
    Pcr.transaction do 
      pcrs.each_with_index do |r,i|
          p = Pcr.new(:extract_id => r[0], :fwd_primer_id => r[1], :rev_primer_id => r[2], :protocol_id => r[3], :notes => ("#{r[7]} " + (r[5] == nil ? "" : "[BJSid:  #{r[5]}]" ))   )
         # puts "#{p.protocol.display_name}\n"
          if r[0] == "00000"
             p.extract_id = @e_control.id
          elsif r[0] == "XXXX"
             p.extract_id = @e_derv.id
          end
          p.save
        
         # ***VERY*** BAD STUFF HERE - because this was used for a first time import we matched up incoming ids DO NOT DO THIS IN GENERAL
         sql = ActiveRecord::Base.connection();
         sql.execute("update pcrs set id = #{r[4]} where id = #{p.id}")
      end
    end
    rescue
      puts "\noops"
      abort
    end
    puts "\ndone!"
  end # end task 

end


