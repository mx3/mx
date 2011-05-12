class AddHtmlColorToIsas < ActiveRecord::Migration
  def self.up
    add_column :isas, :html_color, :string, :limit => 6 
  end

  def self.down
    remove_column :isas, :html_color
  end
end
