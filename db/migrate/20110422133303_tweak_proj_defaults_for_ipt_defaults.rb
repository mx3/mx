class TweakProjDefaultsForIptDefaults < ActiveRecord::Migration
  def self.up
     execute %{alter table projs drop foreign key projs_ibfk_1;}                    
     rename_column :projs, :repository_id, :default_institution_repository_id
     add_column :projs, :collection_code, :string
     execute %{alter table projs add foreign key (default_institution_repository_id) references repositories(id);}  
  end

  def self.down
  end
end
