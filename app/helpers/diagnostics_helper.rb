module DiagnosticsHelper
  def app_revision_info
    @app_revision_info ||= begin
      branch = env_revision_value('GIT_BRANCH', 'APP_GIT_BRANCH', 'SOURCE_BRANCH') || read_revision_file('BRANCH') || git_revision(%w[git rev-parse --abbrev-ref HEAD])
      commit = env_revision_value('GIT_COMMIT', 'GIT_SHA', 'APP_REVISION', 'APP_GIT_COMMIT', 'SOURCE_COMMIT', 'SOURCE_VERSION') || read_revision_file('REVISION') || git_revision(%w[git rev-parse --short HEAD])
      {
        branch: branch.presence,
        commit: commit.presence,
        source: revision_source(branch, commit)
      }
    end
  end

  private

  def env_revision_value(*keys)
    keys.map { |k| ENV[k].to_s.strip.presence }.compact.first
  end

  def read_revision_file(name)
    path = Rails.root.join(name)
    return unless path.exist?

    path.read.to_s.strip.presence
  end

  def git_revision(command)
    return unless Rails.root.join('.git').exist?

    out = IO.popen(command, chdir: Rails.root, err: File::NULL, &:read).to_s.strip
    out.presence
  rescue StandardError
    nil
  end

  def revision_source(branch, commit)
    return :env if %w[GIT_BRANCH APP_GIT_BRANCH SOURCE_BRANCH GIT_COMMIT GIT_SHA APP_REVISION APP_GIT_COMMIT SOURCE_COMMIT SOURCE_VERSION].any? { |k| ENV[k].to_s.strip.present? }
    return :file if Rails.root.join('REVISION').exist? || Rails.root.join('BRANCH').exist?
    return :git if Rails.root.join('.git').exist?

    :unknown
  end
end
