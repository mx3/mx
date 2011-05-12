class RelativePhenotype < Phenotype
  
  GREATER_THAN = "greater_than"
  LESS_THAN = "less_than"
  EQUAL_TO = "equal_to"
  
  belongs_to :quality, :polymorphic => true
  belongs_to :relative_entity, :polymorphic => true
  belongs_to :relative_quality, :polymorphic => true
  
end