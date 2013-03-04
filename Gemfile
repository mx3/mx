# If you have problems with your gems you can rebuild them like so:
#   rvm gemset empty     (answer yes)
#   rvm @global gem install bundler
#   gem update --system
#   bundle

source :gemcutter
  # bundler requires these gems in all environments
  gem "rails", "3.2.12"
  gem "RedCloth"
  gem "bio",  '1.4.1'
  gem "mysql2", '0.3.11'
  gem "rake", "0.9.2.2"
  # gem "ruby-debug19", '0.11.6'
  gem "debugger"
  gem "ruby-graphviz", '0.9.21', :require => "graphviz"
  gem "win32-open3-19", :platforms => :mingw
  gem 'alchemist',  '0.1.2.1'
  gem 'andand', :git => 'https://github.com/panozzaj/andand.git' # contains a couple of fixes to 1.3.1, seems to be the most uptodate
  gem 'attachment_fu', :git =>  'https://github.com/jmoses/attachment_fu.git', :branch => 'rails3'
  gem 'geokit'
  gem 'kaminari'
  gem 'rdf',  '0.3.3'
  gem 'rdf-rdfxml',  '0.3.3.1', :require => 'rdf/rdfxml'
  gem 'vestal_versions',  :tag => 'v1.2.2', :git => 'https://github.com/adamcooper/vestal_versions.git'

  # gems added in 3.0.x
  gem "bourbon"
  gem "haml", "4.0.0"
  gem "sass", "~> 3.2.5"
  gem 'jammit', "0.6.3"

  # gems that have spawned from mx!
  gem "nexus_parser" ,  "1.1.4"
  gem "obo_parser"   ,  "0.3.4"
  gem "rubyMorphbank",  "~>0.2.4"

  # For SVG tag creation - we need to know the browser
  gem "useragent", "~> 0.4.8"
  # Rails 2.3.10, perhaps deprecated in 3.0
  #   gem 'cmess',  '0.2.4' # character encoding guessing
  #   gem "echoe" # !! This may need to be commented out for recent versions of passenger.
  #   config.gem 'addressable',  '2.2.4' # !! 2.2.5 will not work, uninstall from your library completely.
  #   gem 'prototype_legacy_helper', '0.0.0', :git => 'git://github.com/rails/prototype_legacy_helper.git'

group :production do
end

group :development do
  gem "rails-footnotes"
  gem "mongrel", "1.2.0.pre2"
  # gem "thin"
  # gem 'cgi_multipart_eof_fix'
  # gem 'fastthread'
end

group :test do
  # gem "rspec"
  # gem "faker"
  gem 'machinist', '>= 2.0.0.beta2'
  gem 'minitest'
end
