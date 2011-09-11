class QualitativePhenotype < Phenotype
  
  belongs_to :quality, :polymorphic => true
  belongs_to :dependent_entity, :polymorphic => true    # might not be legit in Rails 3
  
end