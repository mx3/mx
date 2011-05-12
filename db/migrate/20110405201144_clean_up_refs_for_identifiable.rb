class CleanUpRefsForIdentifiable < ActiveRecord::Migration
  def self.up
    remove_column :refs, :language_OLD
    remove_column :refs, :DOI
    remove_column :refs, :ISBN
    remove_column :refs, :xref
    remove_column :refs, :pub_med_url
    remove_column :refs, :other_url
  end

  def self.down
  end
end
