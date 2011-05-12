class CleanDeprecatedColumns < ActiveRecord::Migration
  def self.up
    remove_column :otus, :parent_otu_id
    remove_column :otus, :revision_history
    execute %{drop table statements;} # some weird legacy data ?!
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
