class CardinalPhenotype < Phenotype
  
  belongs_to :within_entity, :polymorphic => true
  
end