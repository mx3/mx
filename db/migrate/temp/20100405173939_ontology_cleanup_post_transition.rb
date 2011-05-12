class OntologyCleanupPostTransition < ActiveRecord::Migration
  def self.up
    
    # needs to be run after the rake cleanup for the PEET site

    
    # nuke parts
    # nuke term_exclusions
    # nuke ontologies
    # nuke isas
    
  end

  def self.down
    # very irreversible!
    raise ActiveRecord::IrreversibleMigration
  end
end
