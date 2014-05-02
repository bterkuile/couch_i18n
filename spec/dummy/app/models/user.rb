class User
  include SimplyStored::Couch

  property :email
  devise :database_authenticatable, :recoverable, :rememberable, :trackable

  validates_presence_of :email
end
