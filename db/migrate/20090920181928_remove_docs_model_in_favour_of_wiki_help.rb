class RemoveDocsModelInFavourOfWikiHelp < ActiveRecord::Migration
  def self.up
    drop_table :docs
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
