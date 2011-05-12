class RemoveOldOntologyTables < ActiveRecord::Migration
  def self.up
  
   # the existing foreign key "smartness is preventing 'drop_table :parts_refs' from working, falling back to SQL 
    execute %{ drop table parts_refs;}
    execute %{ drop table parts;}
    execute %{ drop table isas;}
    
    # and a very old one
    execute %{drop table otus_statements;}
  end

  def self.down
    # no going back Jim
  end
end
