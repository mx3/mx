class UpdateActivityClusterForLabels < ActiveRecord::Migration
  def self.up
    add_column :labels, :active_person_id, :integer, :references => :people, :limit => 11, :default => nil
    add_column :labels, :active_msg, :string, :limit => 144
    add_column :labels, :active_level, :integer, :default => 0
  end

  def self.down
    remove_column :labels, :active_person_id
    remove_column :labels, :active_msg
    remove_column :labels, :active_lvl
  end
end
