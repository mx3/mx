class AddIsDbxrefToKeywords < ActiveRecord::Migration
  def self.up
      add_column :keywords, :is_dbxref, :boolean, :default => false
  end

  def self.down
    remove_column :keywords, :is_dbxref
  end
end
