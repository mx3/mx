class AddConfidenceToPcr < ActiveRecord::Migration
  # this replaces result
  def self.up
    add_column :pcrs, :confidence_id, :integer
    add_index :pcrs, :confidence_id
    remove_column :pcrs, :result
  end

  def self.down
    add_column :pcrs, :result, :string
    remove_index :pcrs, :confidence_id
    remove_column :pcrs, :confidence_id
  end
end
