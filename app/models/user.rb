class User < ActiveRecord::Base
  attr_accessible :name, :email, :inbox_size, :oauth_token, :oauth_secret

  def logged_in?
    oauth_token && oauth_secret
  end
end
