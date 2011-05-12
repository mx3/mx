class AddPartsByRefCountTable < ActiveRecord::Migration
  def self.up
    create_table :parts_refs do |t|
          t.primary_key :id
          t.integer :ref_id, :null => false
          t.integer :part_id, :null => false
          t.integer :total, :default => 0, :null => false
          t.timestamp :created_on
          t.timestamp :updated_on
    end
    add_index :parts_refs, [:part_id, :ref_id]
  end

  def self.down
    drop_table :parts_refs
  end
end
