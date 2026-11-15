class Admin::LibrariesController < ApplicationController
  include AdminAuthorization

  def show
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.update('admin_body', partial: 'system') }
      format.html { redirect_to admin_path }
    end
  end

  def update
    ScanLibJob.perform_later
    AuditLogger.log(action: 'library.scan_started', request:)
    flash.now[:success] = t('admin.library.flash.started', default: 'Scan job started...')
    render turbo_stream: turbo_stream.update('flash', partial: 'layouts/flash')
  end

end
