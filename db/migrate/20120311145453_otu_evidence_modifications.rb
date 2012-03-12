
class OtuEvidenceModifications < ActiveRecord::Migration
  def self.up
    rename_column :otus, :sensu, :source_human
    execute %{alter table otus drop foreign key `otus_ibfk_1`;}
    rename_column :otus, :as_cited_in, :source_ref_id
    execute %{alter table otus add foreign key `otus_refs` (source_ref_id) references refs (id);}
    
    add_column :otus, :source_protocol_id, :integer, :size => 11, :references => :protocols
    add_column :otus, :source_ce_id, :integer, :size => 11, :references => :ces
    
    add_index :otus, :source_protocol_id
    add_index :otus, :source_ce_id
    
    execute %{alter table otus add foreign key `otus_protocols` (source_protocol_id) references protocols (id);}
    execute %{alter table otus add foreign key `otus_ces` (source_ce_id) references ces (id);}   
  end

  def self.down
   # rename_column :otus, :source_human, :sensu
   # rename_column :otus, :as_cited_in, :evidence_ref_id
   # remove_column :otus, :evidence_protocol_id
   # remove_column :otus, :evidence_ce_id
  end
end
