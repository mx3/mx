class CreateOntologyRelationships < ActiveRecord::Migration
  def self.up
    execute %{create table ontology_relationships ENGINE=INNODB select * from ontologies;}
    execute %{alter table ontology_relationships modify id integer not null auto_increment primary key;}

    OntologyRelationship.reset_column_information 
    change_table :ontology_relationships do |t|
      t.change :part1_id, :integer, :limit => 11, :null => false
      t.change :part2_id, :integer, :limit => 11, :null => false
      t.change :isa_id, :integer, :limit => 11, :null => false
      t.change :creator_id, :integer, :limit => 11, :null => false
      t.change :updator_id, :integer, :limit => 11, :null => false
      t.change :proj_id, :integer, :limit => 11, :null => false
    end

    rename_column :ontology_relationships, :part1_id, :ontology_class1_id
    rename_column :ontology_relationships, :part2_id, :ontology_class2_id
    rename_column :ontology_relationships, :isa_id, :object_relationship_id

    remove_column :ontology_relationships, :notes

    execute %{alter table ontology_relationships add foreign key (ontology_class1_id) references ontology_classes(id);}
    execute %{alter table ontology_relationships add foreign key (ontology_class2_id) references ontology_classes(id);}
    execute %{alter table ontology_relationships add foreign key (object_relationship_id) references object_relationships(id);}

    execute %{alter table ontology_relationships add foreign key (proj_id) references projs(id);}
    execute %{alter table ontology_relationships add foreign key (updator_id) references people(id);}
    execute %{alter table ontology_relationships add foreign key (creator_id) references people(id);}

    add_index :ontology_relationships, [:object_relationship_id, :ontology_class1_id, :ontology_class2_id], :name => "classes_and_relationship", :unique => true
    add_index :ontology_relationships, [:ontology_class1_id, :ontology_class2_id], :name => "classes_index"
  end

  def self.down

    drop_table :ontology_relationships
  end
end
