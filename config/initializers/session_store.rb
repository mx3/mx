# Be sure to restart your server when you modify this file.

# Edge::Application.config.session_store :cookie_store, :key => '_edge_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Edge::Application.config.session_store :active_record_store, :key => "_mx_session"

#ActionController::Base.session = {
#   :cookie_only => false # allow session to be loaded from params
#}

Edge::Application.config.session_store :active_record_store, :key => "_mx_session"
