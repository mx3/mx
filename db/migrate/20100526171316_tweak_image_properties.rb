class TweakImageProperties < ActiveRecord::Migration
  def self.up
    execute %{ ALTER TABLE image_descriptions CHANGE COLUMN otu_id otu_id int(11);}
  end

  def self.down
  end
end
