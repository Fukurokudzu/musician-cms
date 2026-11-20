require 'rails_helper'

# JS-driven smoke of the export flow: sign in, open the statistics tab,
# click "Download CSV" and confirm the in-flight panel turns into a
# download link once the background job finishes.
RSpec.describe 'Stats export UI', type: :system do
  self.use_transactional_tests = false

  after do
    # browser sign-in and the job write committed rows (plus blob files in
    # the test disk service) — drop them so other specs see a clean slate
    StatsExport.destroy_all
    AuditEvent.delete_all
    ActiveStorage::Attachment.delete_all
    ActiveStorage::VariantRecord.delete_all
    ActiveStorage::Blob.delete_all
    StatEvent.delete_all
    Track.delete_all
    Release.delete_all
    Artist.delete_all
  end

  it 'shows the in-flight panel, then the download link' do
    artist = Artist.create!(title: 'UI Artist')
    release = Release.create!(artist:, title: 'UI Release', status: :published)
    Track.create!(release:, title: 'UI Track', pos: 1, status: :published, plays_count: 3)

    driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900] do |options|
      options.add_argument('no-sandbox')
      options.add_argument('disable-dev-shm-usage')
    end

    visit sign_in_path
    fill_in 'admin_email', with: Setting.admin_email
    fill_in 'admin_password', with: 'admin'
    click_button I18n.t('login.login_btn')

    expect(page).to have_css('#admin_body', wait: 5)
    click_link I18n.t('admin.tabs.stats')

    click_button I18n.t('admin.stats.export_csv')

    expect(page).to have_css('.stats-export-progress:not(.hidden)', wait: 5)

    StatsExportJob.perform_now(StatsExport.last.id, '30')

    expect(page).to have_css('.stats-export-download:not(.hidden)', wait: 10)
    expect(page).to have_link(I18n.t('admin.stats.export_download'))
  end
end
