class AllowNullChrStateIdOnCodingsWithContinuousValues < ActiveRecord::Migration
  def self.up
    change_column :codings, :chr_state_id, :integer, :size => 11, :default => nil, :null => true
    change_column :codings, :chr_state_state, :string, :size => 8, :default => nil, :null => true
  end

  def self.down
    # nothing to see
  end
end
