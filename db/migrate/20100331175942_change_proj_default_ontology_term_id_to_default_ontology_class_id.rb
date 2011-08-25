class ChangeProjDefaultOntologyTermIdToDefaultOntologyClassId < ActiveRecord::Migration
  # run this after the core tables added
  def self.up
    # not necessary in mx3 
    #   execute %{ALTER TABLE projs DROP FOREIGN KEY projs_ibfk_6;}
     rename_column :projs, :default_ontology_term_id, :default_ontology_class_id
     execute %{alter table projs add foreign key (default_ontology_class_id) references ontology_classes(id);}
  end

  def self.down
  end
end
