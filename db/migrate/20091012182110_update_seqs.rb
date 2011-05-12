class UpdateSeqs < ActiveRecord::Migration
  def self.up
    add_column :seqs, :pcr_id, :integer
    add_index :seqs, :pcr_id
    change_column :seqs, :gene_id, :integer, :null => true
    change_column :seqs, :otu_id, :integer, :null => true
    rename_column :seqs, :consensus_sequence, :sequence
  end

  def self.down
    remove_column :seqs, :pcr_id
    change_column :seqs, :gene_id, :integer, :null => false 
    change_column :seqs, :otu_id, :integer, :null => false 
   rename_column :seqs, :sequence, :consensus_sequence
  end
end
