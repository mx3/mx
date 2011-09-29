Sass::Plugin.options = Sass::Plugin.options.merge({
  :syntax=>:scss,
  :template_location=>Rails.root.join('app','sass').to_s,
  :css_location=>Rails.root.join('public','generated').to_s
})
