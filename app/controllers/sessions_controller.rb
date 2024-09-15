class SessionsController < ApplicationController
  def new
  end

  def create
    auth = Auth.new(allowed_params[:admin_email], allowed_params[:admin_password])
    if auth.hashed_id
      session[:hashed_id] = auth.hashed_id
      redirect_to(controller: :admin)
    else
      show_flash(t('flash.alert.login'))
    end
  end

  def destroy
    session[:hashed_id] = nil
    redirect_to(controller: :main, action: :index)
  end

  private

  def allowed_params
    params.permit(:admin_email, :admin_password)
  end
end
