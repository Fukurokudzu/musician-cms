class Auth
  attr_reader :hashed_id

  def initialize(admin_email, admin_password)
    if admin_email == Setting.admin_email && hash_password(admin_password) == Setting.admin_hashed_password
      @hashed_id = Setting.admin_hashed_password
    end
  end

  def hash_password(admin_password)
    self.class.hash_password(admin_password)
  end

  def self.hash_password(admin_password)
    salt = Setting.admin_salt
    BCrypt::Engine.hash_secret(admin_password, salt)
  end

  # Changes the admin password, rotating the salt as well.
  # Invalidates all existing admin sessions (session[:hashed_id] no longer matches).
  def self.change_password!(new_password)
    raise ArgumentError, "Password can't be blank" if new_password.blank?

    Setting.admin_salt = BCrypt::Engine.generate_salt
    Setting.admin_hashed_password = hash_password(new_password)
  end
end
