class AddIsPublicToParts < ActiveRecord::Migration
  def self.up
    add_column :parts, :is_public, :boolean
    execute %{UPDATE parts SET is_public = 1;}  # make them all true by default
  end

  def self.down
    remove_column :parts, :is_public
  end
end
