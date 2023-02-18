class Auth
  
  attr_reader :hashed_id

  def initialize(admin_email, admin_password)
    if admin_email == Setting.admin_email && hash_password(admin_password) == Setting.admin_hashed_password
      salt = BCrypt::Engine.generate_salt
      @hashed_id = BCrypt::Engine.hash_secret(admin_password, salt)
    end
  end

  private
  
  def hash_password(admin_password)
    salt = Setting.admin_salt
    BCrypt::Engine.hash_secret(admin_password, salt)
  end

end