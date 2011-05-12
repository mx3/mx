
class UpdateSensuWithVotesConfidencePositionEtc < ActiveRecord::Migration
  def self.up

    add_column :sensus, :confidence_id, :integer, :references => :confidences, :limit => 11
    add_column :sensus, :position, :integer, :default => 0
    add_column :sensus, :preferred_label_IP_votes, :text
    add_column :sensus, :preferred_by_ref, :boolean, :default => false

    execute %{alter table sensus drop key ref_klass_label;} # pre-indices
    execute %{alter table sensus drop key `all`;}  # pre-indices
    execute %{alter table sensus drop foreign key sensus_ibfk_2;} # the FK constraint on klass_id

    # switch klass_id to ontology_class_id
    add_column :sensus, :ontology_class_id, :integer,  :limit => 11    
    execute %{update sensus set ontology_class_id = klass_id};
    change_column :sensus, :ontology_class_id, :integer, :limit => 11, :null => false
    execute %{alter table sensus add foreign key (ontology_class_id) references ontology_classes(id);}

    add_index :sensus, [:ontology_class_id, :label_id]
    add_index :sensus, [:ontology_class_id, :label_id, :ref_id], :unique => true

    remove_column :sensus, :klass_id

  end

  def self.down
    # well we could, but we're this far...
    raise ActiveRecord::IrreversibleMigration
  end
end
