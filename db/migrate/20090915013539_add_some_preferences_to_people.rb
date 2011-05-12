class AddSomePreferencesToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :pref_mx_display_width, :integer, :limit => 3, :default => 20
    add_column :people, :pref_mx_display_height, :integer, :limit => 3, :default => 10
  end

  def self.down
    remove_column :people, :pref_mx_display_width
    remove_column :people, :pref_mx_display_height
  end
end
