class TweakImageDescriptions < ActiveRecord::Migration
  def self.up
    remove_column :image_descriptions, :svg_txt
  end

  def self.down
    add_column :image_descriptions, :svg_txt, :text
  end
end
