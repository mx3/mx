class AddPrefDefaultRepositoryIdToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, 'pref_default_repository_id', :integer, :size => 11, :null => true, :default => nil, :references => :repositories
  end

  def self.down
    remove_column :people, 'pref_default_repository_id'
  end
end
