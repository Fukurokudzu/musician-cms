class Admin::AboutsController < ApplicationController
  include AdminAuthorization

  def show
    render turbo_stream: turbo_stream.update('admin_body', partial: 'about')
  end
end
