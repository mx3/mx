class ProjLevelEolDumpsOk < ActiveRecord::Migration
  def self.up
    add_column :projs, :is_eol_exportable, :boolean, :default => false
  end

  def self.down
    remove_column :projs, :is_eol_exportable
  end
end
