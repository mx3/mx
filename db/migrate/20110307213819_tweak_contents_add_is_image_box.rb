class TweakContentsAddIsImageBox < ActiveRecord::Migration
  def self.up
    add_column :contents, :is_image_box, :boolean, :default => false
    add_column :content_types, :is_image_box, :boolean, :default => false
  end

  def self.down
    remove_column :contents, :is_image_box
    remove_column :content_types, :is_image_box
  end
end
