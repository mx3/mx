# encoding: utf-8
module ConfidenceHelper

  def confidence_picker_tag(model, method, index) # :yields: a HTML select for scoped by Confidences of applicable_model
    select(model, method, @proj.confidences.by_model(model.to_s).collect{|c| [c.name, c.id]}, {:include_blank => true,}, {:index => index, :name => "#{model.to_s}[#{method.to_s}]"})
  end
  def confidence_span_id(object)
    "cl_#{object.class.to_s}_#{object.id}"
  end
  def confidence_tag(object, options={})
    if object.blank?
      return ""
    else
      span_id = confidence_span_id(object)
      opt = {
        :html_selector            => "##{span_id}",
        :confidence_obj_class     => object.class.to_s,
        :confidence_obj_id        => object.id,
        :proj_id                  => @proj.id
      }.merge(options)

      url = popup_confidences_path(opt)

      render "confidences/confidence_tag", :options=>opt, :span_id => span_id, :url=>url, :object=>object
    end
  end
end
