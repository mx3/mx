# encoding: utf-8
module Json
  def self.simple_autocomplete(values)
    values.collect do |val|
      {
        :id => val,
        :label => val
      }
    end
  end
  def self.format_for_autocomplete_with_display_name(options = {})
    opt = {
       :entries => [],
       :method => nil,
       :value => nil,    # the text submitted in the search
       :response_values => {}
     }.merge!(options)

    opt[:entries].collect{|o|
      {:id => o.id,
        :label=> o.display_name(:type => :selected),
        :response_values=> {
          opt[:method] => o.id
        },
        :label_html => o.display_name(:type => :for_select_list)
      }
    }
  end
end
