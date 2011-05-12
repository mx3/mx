class AddBeatsTables < ActiveRecord::Migration
  def self.up
    create_table(:beats) do |t|
      t.integer    :addressable_id, :nil => false, :references => nil, :size => 11
      t.string     :addressable_type, :nil => false
      t.string     :message, :nil => false
      t.integer    :proj_id, :size => 11, :nil => false
      t.integer    :creator_id, :references => :people, :size => 11, :nil => false
      t.integer    :updator_id, :references => :people, :size => 11, :nil => false
      t.timestamp  :created_on, :nil => false
      t.timestamp  :updated_on, :nil => false
    end
  end

  def self.down
    drop_table :beats
  end
end


