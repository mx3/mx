class CreateEmailResponseTokens < ActiveRecord::Migration
  def self.up
    create_table :email_response_tokens do |t|
      t.string    :token_key,    :null => false
      t.text      :data
      t.integer   :ttl
      t.timestamps
    end
  end

  def self.down
    drop_table :email_response_tokens
  end
end
