# encoding: utf-8
module ConfidenceHelper
 
  def confidence_link(o)
    # TODO: check that confidence_id is present!
    render(:partial => "confidences/confidence_link", :locals => {:obj => o, :msg => ''})
  end

  def confidence_picker_tag(model, method, index) # :yields: a HTML select for scoped by Confidences of applicable_model 
    select(model, method, @proj.confidences.by_model(model.to_s).collect{|c| [c.name, c.id]}, {:include_blank => true,}, {:index => index, :name => "#{model.to_s}[#{method.to_s}]"})
  end

end
