# encoding: utf-8
module SensuHelper

  def sensu_link_for_show(params = {})
    opts = {
      :ref_id => nil,
      :klass_id => nil,
      :label_id => nil,
      :div_id => 'new_sensu'
    }.merge!(params)

    content_tag :div, link_to("Add sensu", :remote => true, :url =>  opts.merge(:action => :new, :controller => :sensu) ), :id => opts[:div_id]
  end

  def public_sensu_tag(sensu)
    content_tag(:strong, sensu.label.name) + " by #{sensu.ref.display_name}"
  end

end
