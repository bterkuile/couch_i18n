class User
  include SimplyStored::Couch
  include Devise::Orm::SimplyStored if defined? Cmtool

  property :email
  devise :database_authenticatable, :recoverable, :rememberable, :trackable if defined? Cmtool

  validates_presence_of :email
end
