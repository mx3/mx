class UpdateAssociationPartsTableToObjectRelationships < ActiveRecord::Migration
  def self.up

    execute 'alter table association_parts drop foreign key association_parts_ibfk_2;'
    rename_column :association_parts, :isa_id, :object_relationship_id
    execute %{alter table association_parts add foreign key (object_relationship_id) references object_relationships(id);}
    
  end

  def self.down
      # don't bother
  end
end
