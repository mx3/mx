require File.expand_path('../boot', __FILE__)

# TODO: R3 Kludge fix(?) for ActionMailer(?) problem see in part
# http://www.ruby-forum.com/topic/198120
class Time
  class << self
    @@months = ["jan", "feb", "mar", "apr", "may",
      "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
    alias :old_utc :utc
    def utc(*args)
      if args.size >= 2
        if args[1].kind_of? String
          args[1] = @@months.index(args[1]) + 1
        end
      end
      old_utc(*args)
    end
  end
end

require 'rails/all'
require 'active_support/builder' unless defined?(Builder) # R3 -> win


# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Edge
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/lib/model_extensions #{config.root}/lib/ontology #{config.root}/lib/ontology/batch_load #{config.root}/lib/ontology/visualize #{config.root}/lib/toolbox)

    # TODO: rails 3
    # config.action_view.javascript_expansions[:defaults] = %w(jquery jquery-ui rails application)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'UTC' # 'Central Time (US & Canada)'
    # config.active_record.default_timezone = :utc
    
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    config.filter_parameters += [:person_password]


    # used in SVG validation and persistence
    ALLOWED_SVG_TAGS        = ['g', 'path', 'line', 'circle']
    ALLOWED_SVG_ATTRIBUTES  = ['d', 'x1', 'x2', 'y1', 'y2', 'stroke-dasharray', 'stroke-linecap', 'stroke-linejoin', 'cx', 'cy', 'r']

    config.action_view.sanitized_allowed_tags = ['ref', 'otu']
    config.action_view.sanitized_allowed_tags += ALLOWED_SVG_TAGS

    config.action_view.sanitized_allowed_attributes = ['id', 'target'] # 'version', 'xmlns'
    config.action_view.sanitized_allowed_attributes += ALLOWED_SVG_ATTRIBUTES


  end
end
