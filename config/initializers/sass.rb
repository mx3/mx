Sass::Plugin.options[:syntax] = :scss
Sass::Plugin.options[:template_location] = Rails.root.join('app','sass').to_s
Sass::Plugin.options[:css_location] = Rails.root.join('public','generated').to_s
