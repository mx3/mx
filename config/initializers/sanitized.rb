# By default all models have the TextHelper#sanitize method called on all fields before they are stored
require 'sanitized' # in lib/
class ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper::ClassMethods
  include Sanitized
end


