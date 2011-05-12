class AddProjIdToSpecimenProperties < ActiveRecord::Migration
  def self.up
    
  # UNCOMMENT THESE LINES FOR OLD DATA MIGRATIONS

    add_column :specimen_determinations, :proj_id_temp, :integer, :limit => 11, :null => false
  #  add_column :specimen_identifiers, :proj_id_temp, :integer, :limit => 11, :null => false
    
    SpecimenDetermination.reset_column_information 
  #  SpecimenIdentifier.reset_column_information
    
    puts "updating"
    
    Specimen.transaction do
      Specimen.find(:all).each do |s|    
        puts s.id
        $person_id = s.creator_id
        $proj_id = s.proj_id
   #    s.specimen_identifiers.each do |i|
   #      i.proj_id_temp = s.proj_id
   #      i.save!
   #    end
        
        s.specimen_determinations.each do |i|
          i.proj_id_temp = s.proj_id
          i.save!
        end
      end
    
    end
    
    rename_column :specimen_determinations, :proj_id_temp, :proj_id
  #  rename_column :specimen_identifiers, :proj_id_temp, :proj_id
    
    SpecimenDetermination.reset_column_information 
  #  SpecimenIdentifier.reset_column_information
      
    execute %{alter table specimen_determinations add foreign key (proj_id) references projs(id);}
  #  execute %{alter table specimen_identifiers add foreign key (proj_id) references projs(id);}

  end

  def self.down
    remove_column :specimen_determinations, :proj_id
  #  remove_column :specimen_identifiers, :proj_id
  end
end
