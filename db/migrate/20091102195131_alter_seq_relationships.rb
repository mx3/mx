class AlterSeqRelationships < ActiveRecord::Migration
  def self.up
    # this isn't what we wanted to do
    drop_table "chromatograms_seqs"
  end

  def self.down
    # just so we can reverse nicely, we don't have any data in here
    create_table 'chromatograms_seqs' 
  end
end
