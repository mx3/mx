class UpdateNamespacesWithIsAdminUseOnly < ActiveRecord::Migration
  def self.up
    add_column :namespaces, :is_admin_use_only, :boolean, :default => false
  end

  def self.down
    remove_column :namespaces, :is_admin_use_only
  end
end
