class CreateObjectRelationships < ActiveRecord::Migration
  def self.up
    execute %{create table object_relationships ENGINE=INNODB select * from isas;}
    execute %{alter table object_relationships modify id integer not null auto_increment primary key;}

    ObjectRelationship.reset_column_information 

    change_table :object_relationships do |t| 
      t.change :updator_id, :integer, :limit => 11, :null => false
      t.change :creator_id, :integer, :limit => 11, :null => false
      t.change :proj_id, :integer, :limit => 11, :null => false
    end

    execute %{alter table object_relationships add foreign key (proj_id) references projs(id);}
    execute %{alter table object_relationships add foreign key (updator_id) references people(id);}
    execute %{alter table object_relationships add foreign key (creator_id) references people(id);}

    add_index :object_relationships, :interaction
    add_index :object_relationships, :complement
    add_index :object_relationships, [:position, :proj_id]
    add_index :object_relationships, [:proj_id, :interaction, :complement], :name => 'proj_int_comp', :unique => true
  end

  def self.down
  end
end
