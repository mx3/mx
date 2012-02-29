# Methods added to this helper will be available to all templates in the application.
module App::LayoutHelper
  # various layout configurations

  # include a css file for a specific class if it exists (also bad for hitting files)
  # TODO: memoize this?!
  def class_css
    if File.exist?("#{Rails.root.to_s}/public/stylesheets/class/#{self.controller.controller_name}.css")
      content_tag(:link, '', :rel => 'Stylesheet', :href => "/stylesheets/class/#{self.controller.controller_name}.css", :type => "text/css")
    end
  end

  # subnav on/off
  def no_subnav
    ['account', 'projs', 'admin']
  end

  # subnav sidenav (class nav) on/off, is off if no subnav
  def no_sidenav
    ['public_contents', 'image_descriptions', 'multikey', 'trait'] 
  end
  
  # determines whether or not to render a picker in the sidenav, remove as pickers are built, is redundant if no_sidenav true
  def no_pickers
    ['trait', 'image_views', 'people', 'associations','chromatograms','morphbank_images', 'distributions', 'object_relationships', 'news', 'measurements', 'ontology', 'protocols', 'tags', 'figures'] 
  end
  
  # toggles new and list buttons in the top right blue box, redundant if no_sidenav is true
  def no_new_or_list
    ['tags', 'contents','morphbank_images', 'people', 'ontology', 'figures', 'trait']
  end
  
end
