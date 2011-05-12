class CreateOntologyClasses < ActiveRecord::Migration
  def self.up
      
    # obo_label_id defaulted in now -- needs testing
    execute %{create table ontology_classes ENGINE=INNODB
      select id, description, taxon_name_id highest_applicable_taxon_name_id, id "obo_label_id", ref_id written_by_ref_id, is_public, obo_dbxref dbxref, proj_id, creator_id, updator_id, created_on, updated_on
      from parts where description is not null and description != "";}

    execute %{alter table ontology_classes modify id integer not null auto_increment primary key;}

      change_table :ontology_classes do |t| 
        t.change :description, :text
        t.rename :description, :definition
        t.change :is_public, :boolean, :default => true
        t.change :obo_label_id, :integer, :limit => 11
        t.change :updator_id, :integer, :limit => 11, :null => false
        t.change :creator_id, :integer, :limit => 11, :null => false
        t.change :proj_id, :integer, :limit => 11, :null => false
        t.change :written_by_ref_id, :integer, :limit => 11
        t.change :highest_applicable_taxon_name_id, :integer, :limit => 11
      end

      add_column :ontology_classes, :genus_differentia_definition, :text  # {1} [2] {3} is a strange {4} [5]  
      # add_column :ontology_classes, :obo_label_id, :integer, :references => :labels, :limit => 11
      add_column :ontology_classes, :illustration_IP_votes, :text # serialized array of IP addresses 1/vote

      # change column doesn't add references
      execute %{alter table ontology_classes add foreign key (proj_id) references projs(id);}
      execute %{alter table ontology_classes add foreign key (written_by_ref_id) references refs(id);}
      execute %{alter table ontology_classes add foreign key (obo_label_id) references labels(id);}
      execute %{alter table ontology_classes add foreign key (updator_id) references people(id);}
      execute %{alter table ontology_classes add foreign key (creator_id) references people(id);}
      execute %{alter table ontology_classes add foreign key (highest_applicable_taxon_name_id)  references taxon_names(id);}

      # execute %{CREATE INDEX definition_index ON ontology_classes (definition(255));} don't do this
      add_index :ontology_classes, :dbxref
      add_index :ontology_classes, [:dbxref, :obo_label_id]
      add_index :ontology_classes, [:id, :dbxref, :obo_label_id]
      
    end

    def self.down
      drop_table :ontology_classes
    end
  end
