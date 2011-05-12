class AddRefIdToTypeSpecimens < ActiveRecord::Migration
  def self.up
    add_column :type_specimens, :ref_id, :integer, :size => 11, :references => :refs
  end

  def self.down
    remove_column :type_specimens, :ref_id
  end
end
