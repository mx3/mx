class AlterPeopleForPreferences < ActiveRecord::Migration
  def self.up
    rename_column :people, :creator_html_color, :pref_creator_html_color
  end

  def self.down
    rename_column :people, :pref_creator_html_color, :creator_html_color 
  end
end
