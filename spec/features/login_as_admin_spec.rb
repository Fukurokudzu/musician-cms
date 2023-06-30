require 'rails_helper'

RSpec.describe 'Admin sign in page', type: :feature do

  scenario 'Signing in as admin' do
    visit sign_in_path
    fill_in 'admin_email', with: 'admin@admin'
    fill_in 'admin_password', with: 'admin'
    click_on 'Login'
    visit admin_path
    expect(page).to have_content('Credentials')
  end
  
  scenario 'Signing in as admin with wrong data' do
    visit sign_in_path
    fill_in 'admin_email', with: 'admin1@admin'
    fill_in 'admin_password', with: 'admin1'
    click_on 'Login'
    expect(page).to have_no_content('Credentials')
  end

end