class AddPrefCreatorColorToPeople < ActiveRecord::Migration
  def self.up
    add_column :people, :creator_html_color, :string, :limit => 6
  end

  def self.down
    remove_column :people, :creator_html_color
  end
end
