class SidekiqAdminConstraint
  def self.matches?(request)
    AdminAuthorization.allowed?(request.session)
  end
end
