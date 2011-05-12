class FixImageAttributionEtc < ActiveRecord::Migration
  def self.up
      rename_column :images, :owner, :maker # the person who generated the image
  end

  def self.down
    rename_column :images, :maker, :owner # the person who generated the image
  end
end
