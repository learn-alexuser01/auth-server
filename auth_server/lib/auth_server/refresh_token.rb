class RefreshToken < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :client
  has_one :access_token, dependent: :destroy

  validates :token, length: { within: 30..50 }, uniqueness: true
  validates :expires_at, presence: true
  validates :access_token, presence: true

  def age
    Time.now - self.updated_at
  end

end