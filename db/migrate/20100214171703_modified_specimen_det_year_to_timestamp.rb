class ModifiedSpecimenDetYearToTimestamp < ActiveRecord::Migration
  
  # this migration will wipe specimen determination det_year on failed run- BACK YOUR DATA UP before running
  def self.up
       my_old_det_data = SpecimenDetermination.find(:all).inject([]){|sum, sd| sum << [sd.id, sd.det_year]}.reject{|a| a[1].blank?}
   
       rename_column :specimen_determinations, :det_year, :det_on
       change_column :specimen_determinations, :det_on, :datetime, :null => false
   
       SpecimenDetermination.reset_column_information # gets the new methods
   
       my_old_det_data.each do |i|
        SpecimenDetermination.find(i[0]).update_attribute(:det_on, Date.new(i[1].to_i) )
        puts "updating #{i[0]} : #{i[1]}"
       end
  end

  def self.down
    # we're altering data here, if you want/have to migrate back you'll need ot scrip
      raise ActiveRecord::IrreversibleMigration
    # rename_column :specimen_determinations, :det_on, :det_year
    # change_column :specimen_determinations, :det_year, :string, :null => true, :limit => 4
  end
end
