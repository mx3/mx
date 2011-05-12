class AddIsAcronymToParts < ActiveRecord::Migration
  def self.up
    add_column :parts, :is_acronym, :boolean
    execute %{UPDATE parts SET is_acronym = 1;}  # make them all true by default
  end

  def self.down
    remove_column :parts, :is_acronym
  end
end
