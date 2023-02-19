class AdminController < ApplicationController

  before_action :authorize

  def index
  end

  def update
    
  end
  
  private

  def authorize
    render('/sessions/new') unless admin?
  end

  def admin?
    session[:hashed_id] ||= nil
  end
end
