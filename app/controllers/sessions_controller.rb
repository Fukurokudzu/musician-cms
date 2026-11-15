class SessionsController < ApplicationController
  def new; end

  def create
    auth = Auth.new(allowed_params[:admin_email], allowed_params[:admin_password])
    if auth.hashed_id
      session[:hashed_id] = auth.hashed_id
      AuditLogger.log(action: 'auth.sign_in', actor: Setting.admin_email, request:)
      redirect_to(controller: :admin)
    else
      attempted_email = allowed_params[:admin_email].to_s.truncate(255)
      AuditLogger.log(action: 'auth.sign_in_failed', actor: attempted_email.presence || 'unknown',
                      metadata: { email: attempted_email }, request:)
      show_flash(t('flash.alert.login'))
    end
  end

  def destroy
    AuditLogger.log(action: 'auth.sign_out', actor: Setting.admin_email, request:)
    session[:hashed_id] = nil
    redirect_to(controller: :main, action: :index)
  end

  private

  def allowed_params
    params.permit(:admin_email, :admin_password, :authenticity_token, :commit)
  end
end
