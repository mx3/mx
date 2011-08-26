class TweakIndeciesOnSensus < ActiveRecord::Migration
  def self.up
    
  # mx3 struck
  #  execute %{alter table sensus drop foreign key sensus_ibfk_9;}                     # was no point to this one

    execute %{alter table sensus add foreign key (label_id) references labels(id);}   # blatantly missing
    
  end

  def self.down
  end
end
