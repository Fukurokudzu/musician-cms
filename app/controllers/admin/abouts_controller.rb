class Admin::AboutsController < ApplicationController
  include AdminAuthorization

  def show
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update('admin_body', partial: 'about') }
      format.html { redirect_to admin_path }
    end
  end
end
