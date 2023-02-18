class AdminController < ApplicationController

  def index
    if admin?
      
    else
      render('/sessions/new')
    end
  end
  
  private

  def admin?
    session[:hashed_id] ||= nil
  end
end
