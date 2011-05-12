class TweakNamespaces2 < ActiveRecord::Migration
  def self.up
    change_column :namespaces, :short_name, :string, :null => false
    remove_column :namespaces, :url_access
  end

  def self.down
  end
end
