class User
  include SimplyStored::Couch
  include Devise::Orm::SimplyStored

  property :email
  devise :database_authenticatable, :recoverable, :rememberable, :trackable

  validates_presence_of :email
end
