class AddPhenotypeToState < ActiveRecord::Migration
  def self.up
    add_column :chr_states, :phenotype_id, :integer, :size => 11, :references => nil
    add_column :chr_states, :phenotype_type, :string
    add_column :chrs, :phenotype_class, :string
  end

  def self.down
    remove_column :chr_states, :phenotype_id
    remove_column :chr_states, :phenotype_type
    remove_column :chrs, :phenotype_class
  end
end
