class MiscUpdates2 < ActiveRecord::Migration
  def self.up
      add_column :confidences, :html_color, :string, :limit => 8
  end

  def self.down
      remove_column :confidence, :html_color
  end
end
