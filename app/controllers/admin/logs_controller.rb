module Admin
  class LogsController < ApplicationController
    include AdminAuthorization

    PER_PAGE = 25
    TAIL_BYTES = LogFile::TAIL_BYTES

    def show
      load_page_data

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.update('admin_body', partial: 'admin/logs/logs') }
        format.html { redirect_to admin_path }
      end
    end

    # Removes every audit_events row, then writes a single fresh entry so the
    # table shows who cleared it and how much was removed.
    def clear_audit
      removed = AuditEvent.count
      AuditEvent.delete_all
      AuditLogger.log(action: 'logs.audit_cleared', request:, metadata: { removed: })
      flash.now[:success] = t('admin.logs.audit_cleared', count: removed)
      respond_with_logs
    rescue StandardError => e
      flash.now[:error] = t('admin.logs.clear_failed', error: e.message)
      respond_with_logs
    end

    # Truncates the raw log file to zero bytes. The broadcast/file logger
    # holds the fd in append mode, so it keeps writing from the start of the
    # now-empty file.
    def clear_file
      info = LogFile.info
      if info.exists
        File.truncate(info.path, 0)
        AuditLogger.log(action: 'logs.file_cleared', request:, metadata: { path: info.path.to_s })
        flash.now[:success] = t('admin.logs.file_cleared')
      else
        flash.now[:error] = t('admin.logs.stdout_missing')
      end
      respond_with_logs
    rescue StandardError => e
      flash.now[:error] = t('admin.logs.clear_failed', error: e.message)
      respond_with_logs
    end

    # Streams the raw log to an admin browser. ?scope=tail (default) sends
    # only the last TAIL_BYTES; ?scope=full sends the whole file, however
    # large it is.
    def download
      info = LogFile.info
      unless info.exists
        render plain: t('admin.logs.stdout_missing'), status: :not_found
        return
      end

      filename = "#{Rails.env}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.log"

      if params[:scope] == 'full'
        send_file info.path, filename:, type: 'text/plain', disposition: 'attachment'
      else
        offset = [info.file_size - TAIL_BYTES, 0].max
        send_file info.path, filename: "#{Rails.env}-tail-#{Time.current.strftime('%Y%m%d-%H%M%S')}.log",
                             type: 'text/plain', disposition: 'attachment',
                             offset:, length: info.file_size - offset
      end
    end

    private

    def load_page_data
      @category = params[:category].presence_in(['all', *AuditEvent::CATEGORIES]) || 'all'
      scope = AuditEvent.recent
      scope = scope.of_category(@category) unless @category == 'all'

      @total_count = scope.count
      @total_pages = [(@total_count / PER_PAGE.to_f).ceil, 1].max
      @page = params[:page].to_i.clamp(1, @total_pages)
      @events = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
      @log_file = LogFile.info
    end

    def respond_with_logs
      load_page_data
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('admin_body', partial: 'admin/logs/logs'),
            turbo_stream.update('flash', partial: 'layouts/flash')
          ]
        end
        format.html { redirect_to admin_path }
      end
    end
  end
end
