class BuildPhylodb < ActiveRecord::Migration
  
  # This Rails migration is a translation of the PhyloDB sql code by Lapp & Piel, see
  # https://github.com/mjy/biosql/blob/master/sql/biosql-phylodb-pg.sql and
  # https://github.com/mjy/biosql/blob/master/sql/biosql-phylodb-mysql.sql
  # 
  # At present it requires the inclusion of the RedHill foreign key library.
  # 
  # The original SQL does not follow Rails conventions.  For the most part
  # this migration follows the original, and breaks conventions.  However, there
  # are several notable exceptions:
  # * All IDs are Int(11), not Int(10)
  # * Multi-column primary keys were not created, instead an additional
  # :id primary key is created along with the join table, for the following tables:
  # ** edge_qualifier_value, node_qualifier_value, tree_dbxref, tree_qualifier_value
  #
  # 
  
  def self.up
    
    # tree
    create_table(:tree, :primary_key => :tree_id) do |t|
      t.string  :name, :size => 32, :nill => false
      t.string  :identifier, :size => 32
      t.boolean :is_rooted, :default => true
      t.integer :node_id, :size => 11, :nil => false
    end

    add_index :tree, :name, :unique => true

    # node
    create_table(:node, :primary_key => :node_id) do |t|
      t.string :label, :size => 255
      t.integer :tree_id, :size => 11, :nil => false
      t.integer :bioentry_id, :size => 11 # references?
      t.integer :taxon_id, :size => 11    # references?
      t.integer :left_idx
      t.integer :right_idx  
    end

    add_index :node, [:label, :tree_id], :unique => true
    add_index :node, [:left_idx, :tree_id], :unique => true
    add_index :node, [:right_idx, :tree_id], :unique => true
    add_index :node, :tree_id, :name => :node_tree_id
    add_index :node, :bioentry_id, :name => :node_bioentry_id
    add_index :node, :taxon_id, :name => :node_taxon_id

    # edge
    create_table(:edge, :primary_key => :edge_id) do |t|
      t.integer :child_node_id, :size => 11, :nil => false
      t.integer :parent_node_id, :size => 11, :nil => false
    end

    add_index :edge, [:child_node_id, :parent_node_id], :unique => true
    add_index :edge, :parent_node_id, :name => :edge_parent_node_id

    # node_path
    create_table(:node_path, :id => false) do |t|
      t.integer :child_node_id, :size => 11, :nil => false, :references => :node #TODO: true?
      t.integer :parent_node_id, :size => 11, :nil => false, :references => :node
      t.text :path
      t.integer :distance, :size => 11
    end

    add_index :node_path, :parent_node_id, :name => :node_path_parent_node_id

    # edge_qualifier_value
    create_table (:edge_qualifier_value) do |t|
      t.text :value
      t.integer :edge_id, :size => 11, :nil => false, :references => :edge 
      t.integer :term_id, :size => 11, :nil => false, :references => nil # TODO make this customizable
    end

    add_index :edge_qualifier_value, :term_id, :name => :ea_val_term_id
    add_index :edge_qualifier_value, [:edge_id, :term_id] # mimic the primary key

    # node_qualifier_value
    create_table (:node_qualifier_value) do |t|
      t.text :value
      t.integer :node_id, :size => 11, :nil => false, :references => :node
      t.integer :term_id, :size => 11, :nil => false, :references => nil # TODO make this customizable
    end

    add_index :node_qualifier_value, :term_id, :name => :na_val_term_id
    add_index :node_qualifier_value, [:node_id, :term_id] # mimic the primary key

    # below are tables currently in the pg.sql file, but not in mysql.sql

    # tree_root
    create_table(:tree_root, :primary_key => :tree_root_id) do |t|   
       t.integer :tree_id, :size => 11, :nil => false, :references => :tree
       t.integer :node_id, :size => 11, :nil => false, :references => :node
       t.boolean :is_alternate, :default => false
       t.float   :significance
    end
    
    add_index :tree_root, [:tree_id, :node_id], :unique => true

    # tree_dbxref
    create_table (:tree_dbxref) do |t|
      t.integer :tree_id, :size => 11, :nil => false, :references => :tree
      t.integer :dbxref_id, :size => 11, :nil => false, :references => nil # TODO: configure
      t.integer :term_id, :size => 11, :nil => false, :references => nil
    end

    add_index :tree_dbxref, [:tree_id, :dbxref_id], :unique => true
    add_index :tree_dbxref, :dbxref_id, :name => :tree_dbxref_il

    # tree_qualifier_value
    create_table (:tree_qualifier_value) do |t|
      t.integer :tree_id, :size => 11, :nil => false, :references => :tree
      t.integer :term_id, :size => 11, :nil => false, :references => nil # TODO: configure
      t.text :value
      t.integer :rank, :nil => false, :default => 0 
    end
    
    add_index :tree_qualifier_value, [:tree_id, :term_id, :rank], :name => :pseudo_primary_key
  
    # node_dbxref
    create_table (:node_dbxref) do |t|
      t.integer :node_id, :size => 11, :nil => false, :references => :node
      t.integer :dbxref_id, :size => 11, :nil => false, :references => nil # TODO: configure
      t.integer :term_id, :size => 11, :nil => false, :references => nil# TODO: configure
    end

    add_index :node_dbxref, [:node_id, :dbxref_id, :term_id], :name => :pseudo_primary_key, :unique => true # is unique true true?

    # node_taxon
    create_table(:node_taxon, :primary_key => :node_taxon_id) do |t|
      t.integer :node_id, :size => 11, :nil => false, :references => :node
      t.integer :taxon_id, :size => 11, :nil => false, :references => nil # TODO: configure
      t.integer :rank, :nil => false, :default => 0
    end

    add_index :node_taxon, [:node_id, :taxon_id, :rank], :unique => true

    # node_bioentry
    create_table(:node_bioentry, :primary_key => :node_bioentry_id) do |t|
      t.integer :node_id, :size => 11, :nil => false, :references => :node
      t.integer :bioentry_id, :size => 11, :nil => false, :references => nil # to configure
      t.integer :rank, :nil => false, :default => 0
    end
    
    add_index :node_bioentry, [:node_id, :bioentry_id, :rank], :unique => true
  end

  def self.down
    drop_table :tree ;
    drop_table :tree_root;
    drop_table :tree_dbxref;
    drop_table :tree_qualifier_value;
    drop_table :node ;
    drop_table :node_dbxref ;
    drop_table :node_taxon ;
    drop_table :node_bioentry;
    drop_table :edge;
    drop_table :node_path ;
    drop_table :node_qualifier_value;
  end
end
