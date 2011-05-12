class TweakLots < ActiveRecord::Migration
  # this deletes without checking data, you might want to convert to Tags first
  def self.up
    # USE TAGS
    remove_column :lots, :dnd
    remove_column :lots, :determination_unsure
    remove_column :lots, :single_specimen
  end

  def self.down
    add_column :lots, :dnd, :boolean
    add_column :lots, :determination_unsure, :boolean
    add_column :lots, :single_specimen, :boolean
  end
end
