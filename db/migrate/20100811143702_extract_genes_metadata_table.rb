class ExtractGenesMetadataTable < ActiveRecord::Migration
  def self.up
    create_table :extracts_genes do |t|
      t.primary_key :id
      t.text :notes
      t.timestamp :created_on, :null => false
      t.timestamp :updated_on, :null => false
    end
    
      add_column :extracts_genes, :gene_id, :integer, :null => false, :size => 11, :references => :genes
      add_column :extracts_genes, :confidence_id, :integer, :null => false, :size => 11, :references => :confidences
      add_column :extracts_genes, :extract_id, :integer, :null => false, :size => 11, :references => :extracts
      
      add_column :extracts_genes, :proj_id,  :integer, :null => false, :size => 11, :references => :projs
      add_column :extracts_genes, :updator_id, :integer, :references => :people, :size => 11, :null => false, :references => :people
      add_column :extracts_genes, :creator_id, :integer, :references => :people, :size => 11, :null => false, :references => :people
  end

  def self.down
      drop_table :extracts_genes
  end
end
