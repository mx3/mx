class AddIsOntologyAdminToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :is_ontology_admin, :boolean
  end

  def self.down
    remove_column :people, :is_ontology_admin
  end
end
