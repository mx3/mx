class TermExclusions < ActiveRecord::Migration
  def self.up
    create_table :term_exclusions do |t|
          t.string  :name
          t.integer :count, :default => 0
          t.integer :proj_id
          t.timestamp :created_on
          t.timestamp :updated_on
    end
    add_index :term_exclusions, :name
  end

  def self.down
    drop_table :term_exclusions
  end
end
