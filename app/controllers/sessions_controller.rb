class SessionsController < ApplicationController

  def new
  end

  def create
    auth = Auth.new(allowed_params)
    if auth.hashed_id
      session[:hashed_id] = auth.hashed_id
      redirect_to(controller: :admin)
    else
      #TODO Wrong user / pass message
    end
  end

  def destroy
    session[:hashed_id] = nil
  end

  private

  def allowed_params
    params.permit(:admin_email, :admin_password)
  end

end
