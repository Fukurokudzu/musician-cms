require 'rails_helper'
require_relative('../../app/jobs/scan_lib_helper')

RSpec.describe ScanLibJob, type: :job do
  
  include ScanLibHelper
  
  let(:artist) { create(:artist) }

  # it "Creates job when user saved" do
  #   expect { create(:artist) }.to have_enqueued_job(ScanLibJob)
  # end

  it "Correctly shows releases for selected artist scan" do
    expect(ScanLibHelper.get_releases_list(artist.title)).to be_instance_of(Array)
  end
  
  it "Correctly shows tracks for selected release scan" do
    release_path = ScanLibHelper.get_releases_list(artist.title).first
    expect(ScanLibHelper.get_tracks_list(release_path)).to be_instance_of(Array)
  end

  it "Finds cover for selected release scan" do
    release_path = ScanLibHelper.get_releases_list(artist.title).first
    expect(ScanLibHelper.get_release_cover(release_path)).to eql(["cover.jpg"])
  end

end
