class RemoveForeignKeyConstraintsReferencingParts < ActiveRecord::Migration
  def self.up
   # DO NOTHING IN mx3
   #  execute %{ALTER TABLE sensus DROP FOREIGN KEY sensus_ibfk_3;} # the one on parts
  end

  def self.down
    # irreversible
  end
end
