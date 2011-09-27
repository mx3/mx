class AddDefaultSpecimenIdentifierNamespaceToProjs < ActiveRecord::Migration
  
  def self.up
    add_column :projs, 'default_specimen_identifier_namespace_id', :integer, :size => 11, :null => true, :default => nil, :references => :namespaces
  end

  def self.down
    remove_column :projs, :default_specimen_identifier_namespace_id
  end
  
end
