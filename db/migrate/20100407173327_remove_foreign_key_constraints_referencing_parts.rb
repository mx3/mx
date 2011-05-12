class RemoveForeignKeyConstraintsReferencingParts < ActiveRecord::Migration
  def self.up
    execute %{ALTER TABLE sensus DROP FOREIGN KEY sensus_ibfk_3;} # the one on parts
  end

  def self.down
    # irreversible
  end
end
