require 'machinist/active_record'
Machinist.configure do |config|
  config.cache_objects = false
end

# Here you can define the blueprints for objects in the system
# So you can create 'valid' objects quickly for testing... setting up relationships
# and things of that nature.
#
Person.blueprint do
  last_name { "last_#{sn}" }
  first_name {"first_#{sn}"}
  login { "needs_to_be_four+#{sn}" }
  email { "#{object.first_name}@#{object.last_name}.org" }
  password { '12345678' }
  password_confirmation { object.password }
  is_admin { false }
  creates_projects { false }
end

Proj.blueprint do
  name { "Project #{sn}" }
  creator { Person.make! }
  updator { Person.make! }
end

Image.blueprint do
  proj    { Proj.make! }
  creator { object.proj.people.first }
  updator { object.creator }
  maker { "maker_#{sn}" }
  copyright_holder {"copyright_holder_#{sn}" }
  file_name { "file_#{sn}.png" }
  file_md5 { UUID.create_v4.to_s }
end

Ce.blueprint do
  proj { Proj.make! }
  creator { object.proj.people.first }
  updator { object.creator }
  is_public { true }
end

Confidence.blueprint do
  name { ActiveSupport::SecureRandom.hex(6) }
  proj { Proj.make! }
  creator { object.proj.people.first }
  updator { object.creator }
  html_color { "abcdef" }
  applicable_model {Confidence::MODELS_WITH_CONFIDENCE.values.sample}
end
