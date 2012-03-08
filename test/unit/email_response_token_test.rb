require 'test_helper'

class EmailResponseTokenTest < ActiveSupport::TestCase
  test "creating a token is easy" do
    assert_difference "EmailResponseToken.count" do
      EmailResponseToken.create_token!(:foo => 1)
    end
  end
  test "tokens are expired after ttl passes" do
    token = EmailResponseToken.create_token!(:foo => 1, :ttl => 1.minute)
    assert !token.expired?
    assert token.expired?(Time.now + 1.hour.ago)
  end
  test "find a token" do
    token = EmailResponseToken.create_token!(:foo => 1, :ttl => 1.second)
    assert_equal token, EmailResponseToken.find_token(token.token_key)
  end
end
