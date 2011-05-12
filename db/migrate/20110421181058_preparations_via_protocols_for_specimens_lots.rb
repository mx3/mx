class PreparationsViaProtocolsForSpecimensLots < ActiveRecord::Migration
  def self.up
    add_column :specimens, :preparation_protocol_id, :integer, :size => 11, :references => :protocols
    add_column :lots, :preparation_protocol_id, :integer, :size => 11, :references => :protocols
    remove_column :specimens, :preparations # wasn't used yet
  end

  def self.down
    remove_column :specimens, :preparation_protocol_id
    remove_column :lots, :preparation_protocol_id
  end
end
