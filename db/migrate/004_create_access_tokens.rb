class CreateAccessTokens < ActiveRecord::Migration

  def self.up
    create_table :access_tokens do |t|
      t.timestamps
      t.integer :refresh_token_id
      t.datetime :expires_at
    end
  end

  def self.down
    drop_table :access_tokens
  end

end