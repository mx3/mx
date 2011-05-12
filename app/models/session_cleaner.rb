# See http://realityforge.org/code/rails/2006/03/01/removing-stale-rails-sessions.html

class SessionCleaner
  def self.remove_stale_sessions
    ActiveRecord::SessionStore::Session.destroy_all( ['updated_at <?', 2.days.ago] ) 
  end
end

# Add this to your chron
# */10 * * * * ruby /full/path/to/script/runner -e production "SessionCleaner.remove_stale_sessions"

