class QualitativePhenotype < Phenotype
  
  belongs_to :quality, :polymorphic => true
  belongs_to :dependent_entity, :polymorphic => true
  
end