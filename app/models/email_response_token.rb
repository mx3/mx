# These tokens are help connect a response from an email with some private data.
# The token value is so HUGE that it is effectively obfuscated.
# These are deleted once they are used.
class EmailResponseToken < ActiveRecord::Base
  serialize :data, Hash
  validates_uniqueness_of :token_key

  def self.create_token!(data = {})
    token = EmailResponseToken.new
    token.token_key = SecureRandom.hex(20)
    token.ttl = data.delete(:ttl) || 7.days
    token.data = data
    token.save!
    token
  end

  def self.find_token(key)
    response = EmailResponseToken.where(:token_key => key).first
    if response && response.expired?
      response.destroy
      nil
    else
      response
    end
  end

  def expired?(at = Time.now)
    at > (self.created_at + ttl)
  end
end
