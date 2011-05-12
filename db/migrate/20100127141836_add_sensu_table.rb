class AddSensuTable < ActiveRecord::Migration
  def self.up
    # for some reaons integer not defaulting to 11
    create_table :sensus do |t|
      t.integer :ref_id, :null => false, :limit => 11
      t.integer :klass_id, :references => :parts, :null => false, :limit => 11
      t.integer :label_id, :references => :parts, :null => false, :limit => 11
      t.integer :proj_id, :null => false, :limit => 11
      t.text :notes
      t.integer :creator_id, :references => :people, :null => false, :limit => 11
      t.integer :updator_id, :references => :people, :null => false, :limit => 11
      t.timestamp :created_on, :null => false
      t.timestamp :updated_on, :null => false
    end
      add_index :sensus, :ref_id
      add_index :sensus, :klass_id
      add_index :sensus, :label_id
      add_index :sensus, [:ref_id, :klass_id, :label_id], :name => "ref_klass_label", :unique => true
      add_index :sensus, [:ref_id, :klass_id, :label_id, :proj_id], :name => "all", :unique => true
  end

  def self.down
    drop_table :sensu
  end
end
