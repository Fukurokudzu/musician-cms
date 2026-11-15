module DiagnosticsHelper
  REVISION_ENV_KEYS = %w[
    GIT_BRANCH APP_GIT_BRANCH SOURCE_BRANCH
    GIT_COMMIT GIT_SHA APP_REVISION APP_GIT_COMMIT
    SOURCE_COMMIT SOURCE_VERSION
  ].freeze

  def app_revision_info
    @app_revision_info ||= {
      branch: current_branch.presence,
      commit: current_commit.presence,
      source: revision_source
    }
  end

  private

  def current_branch
    env_value('GIT_BRANCH', 'APP_GIT_BRANCH', 'SOURCE_BRANCH') ||
      read_revision_file('BRANCH') ||
      git_revision(%w[git rev-parse --abbrev-ref HEAD])
  end

  def current_commit
    env_value('GIT_COMMIT', 'GIT_SHA', 'APP_REVISION', 'APP_GIT_COMMIT', 'SOURCE_COMMIT', 'SOURCE_VERSION') ||
      read_revision_file('REVISION') ||
      git_revision(%w[git describe --tags --exact-match]) ||
      git_revision(%w[git rev-parse --short HEAD])
  end

  def env_value(*keys)
    keys.map { |key| ENV[key].to_s.strip.presence }.compact.first
  end

  def read_revision_file(name)
    path = Rails.root.join(name)
    return unless path.exist?

    path.read.to_s.strip.presence
  end

  def git_revision(command)
    return unless Rails.root.join('.git').exist?

    IO.popen(command, chdir: Rails.root, err: File::NULL, &:read).to_s.strip.presence
  rescue StandardError
    nil
  end

  def revision_source
    return :env if REVISION_ENV_KEYS.any? { |key| ENV[key].to_s.strip.present? }
    return :file if Rails.root.join('REVISION').exist? || Rails.root.join('BRANCH').exist?
    return :git if Rails.root.join('.git').exist?

    :unknown
  end
end
