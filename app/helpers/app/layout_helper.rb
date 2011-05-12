# Methods added to this helper will be available to all templates in the application.
module App::LayoutHelper
  # various layout configurations

  # include a css file for a specific class if it exists (also bad for hitting files)
  # TODO: memoize this?!
  def class_css
    if File.exist?("#{Rails.root.to_s}/public/stylesheets/class/#{self.controller.controller_name}.css")
      "<link rel=\"Stylesheet\" href=\"/stylesheets/class/#{self.controller.controller_name}.css\" type=\"text/css\" />".html_safe
    end
  end

  # subnav on/off
  def no_subnav
    ['account', 'proj', 'admin', 'doc' ]
  end

  # subnav sidenav (class nav) on/off, is off if no subnav
  def no_sidenav
    ['public_content', 'image_description', 'multikey'] 
  end
  
  # determines whether or not to render a picker in the sidenav, remove as pickers are built, is redundant if no_sidenav true
  def no_pickers
    ['person', 'association','chromatogram','morphbank_image', 'distribution', 'object_relationship', 'news', 'measurement', 'ontology', 'protocols', 'tag', 'figure'] 
  end
  
  # toggles new and list buttons in the top right blue box, redundant if no_sidenav is true
  def no_new_or_list
    ['tag', 'content','morphbank_image', 'person', 'ontology', 'figure']
  end
  
end
