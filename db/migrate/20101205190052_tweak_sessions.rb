class TweakSessions < ActiveRecord::Migration
  def self.up
    # fixes a custom create
    change_column :sessions, :session_id, :string, :nil => false
  end

  def self.down
    # do nothing
  end
end
