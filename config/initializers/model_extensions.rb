require  'model_extensions/has_standard_fields' 
ActiveRecord::Base.send(:include, ModelExtensions::HasStandardFields)
# require  'has_pulse' 
# ActiveRecord::Base.send(:include, ModelExtensions::HasPulse)

