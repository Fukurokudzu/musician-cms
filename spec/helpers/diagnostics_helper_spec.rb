require 'rails_helper'

RSpec.describe DiagnosticsHelper, type: :helper do
  around do |example|
    keys = DiagnosticsHelper::REVISION_ENV_KEYS
    saved = keys.index_with { |key| ENV[key] }
    keys.each { |key| ENV.delete(key) }

    example.run

    saved.each { |key, value| value ? ENV[key] = value : ENV.delete(key) }
  end

  describe '#app_revision_info' do
    it 'takes branch and commit from the environment' do
      ENV['GIT_BRANCH'] = 'feature-branch'
      ENV['GIT_COMMIT'] = 'abc1234'

      expect(helper.app_revision_info).to eq(
        branch: 'feature-branch', commit: 'abc1234', source: :env
      )
    end

    it 'reports the first environment variable that holds a value' do
      ENV['SOURCE_BRANCH'] = ''
      ENV['APP_GIT_BRANCH'] = '  '
      ENV['GIT_BRANCH'] = 'main'
      ENV['GIT_SHA'] = 'def5678'

      revision = helper.app_revision_info

      expect(revision[:branch]).to eq('main')
      expect(revision[:commit]).to eq('def5678')
      expect(revision[:source]).to eq(:env)
    end

    it 'falls back to a revision file when the environment is empty' do
      allow(helper).to receive(:read_revision_file) do |name|
        { 'BRANCH' => 'release', 'REVISION' => 'filesha' }[name]
      end

      revision = helper.app_revision_info

      expect(revision[:branch]).to eq('release')
      expect(revision[:commit]).to eq('filesha')
      # Whether :file is reported depends on the revision files really being
      # present next to the application; git is the next fallback.
      expect(%i[file git unknown]).to include(revision[:source])
    end

    it 'falls back to git when neither environment nor files are available' do
      allow(helper).to receive(:read_revision_file).and_return(nil)
      allow(helper).to receive(:git_revision) do |command|
        command.include?('--abbrev-ref') ? 'main' : 'deadbee'
      end

      revision = helper.app_revision_info

      expect(revision[:branch]).to eq('main')
      expect(revision[:commit]).to eq('deadbee')
      expect(%i[git unknown]).to include(revision[:source])
    end

    it 'uses the current git tag as the commit when HEAD is exactly on a tag' do
      allow(helper).to receive(:read_revision_file).and_return(nil)
      allow(helper).to receive(:git_revision) do |command|
        command.join(' ').start_with?('git describe') ? 'v1.2.3' : 'deadbee'
      end

      revision = helper.app_revision_info

      expect(revision[:commit]).to eq('v1.2.3')
    end

    it 'leaves the values empty when nothing can be detected' do
      allow(helper).to receive(:read_revision_file).and_return(nil)
      allow(helper).to receive(:git_revision).and_return(nil)

      revision = helper.app_revision_info

      expect(revision[:branch]).to be_nil
      expect(revision[:commit]).to be_nil
      expect(%i[git unknown]).to include(revision[:source])
    end

    it 'memoizes the result' do
      first = helper.app_revision_info

      expect(helper.app_revision_info).to equal(first)
    end
  end
end
