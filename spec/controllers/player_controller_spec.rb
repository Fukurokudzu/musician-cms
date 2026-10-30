require 'rails_helper'

RSpec.describe PlayerController, type: :controller do
  describe '#find_next_or_previous_track' do
    let(:artist) { create(:artist, title: 'Test Artist') }
    let(:release) { create(:release, artist:, title: 'Test Release') }
    let(:track1) { create(:track, release:, title: 'Track 1', pos: 1) }
    let(:track2) { create(:track, release:, title: 'Track 2', pos: 2) }
    let(:track3) { create(:track, release:, title: 'Track 3', pos: 3) }

    before do
      [track1, track2, track3]
    end

    it 'returns next track when direction is next' do
      result = controller.send(:find_next_or_previous_track, track1, :next)
      expect(result).to eq(track2)
    end

    it 'returns previous track when direction is prev' do
      result = controller.send(:find_next_or_previous_track, track3, :prev)
      expect(result).to eq(track2)
    end

    it 'returns track with higher ID when no track with higher position exists' do
      track_same_pos = create(:track, release:, title: 'Same Pos', pos: 3, id: track3.id + 1)
      result = controller.send(:find_next_or_previous_track, track3, :next)
      expect(result).to eq(track_same_pos)
    end

    it 'returns track with lower ID when no track with lower position exists' do
      track_same_pos = create(:track, release:, title: 'Same Pos', pos: 1, id: track1.id - 1)
      result = controller.send(:find_next_or_previous_track, track1, :prev)
      expect(result).to eq(track_same_pos)
    end

    it 'returns nil when there are no next tracks by position or ID' do
      result = controller.send(:find_next_or_previous_track, track3, :next)
      expect(result).to be_nil
    end

    it 'returns nil when there are no previous tracks by position or ID' do
      result = controller.send(:find_next_or_previous_track, track1, :prev)
      expect(result).to be_nil
    end
  end

  describe '#select_track' do
    let(:artist) { create(:artist, title: 'Test Artist') }
    let(:release) { create(:release, artist:, title: 'Test Release') }

    # Creation (id) order deliberately differs from position order,
    # so wrap-around must follow pos, not id.
    let!(:last_track) { create(:track, release:, title: 'Last Track', pos: 3) }
    let!(:first_track) { create(:track, release:, title: 'First Track', pos: 1) }
    let!(:middle_track) { create(:track, release:, title: 'Middle Track', pos: 2) }

    it 'returns the next track by position' do
      result = controller.send(:select_track, current_track: first_track, direction: :next)
      expect(result).to eq(middle_track)
    end

    it 'returns the previous track by position' do
      result = controller.send(:select_track, current_track: middle_track, direction: :prev)
      expect(result).to eq(first_track)
    end

    it 'wraps to the first track of the release when moving next from the last track' do
      result = controller.send(:select_track, current_track: last_track, direction: :next)
      expect(result).to eq(first_track)
    end

    it 'stays on the current track when moving prev from the first track' do
      result = controller.send(:select_track, current_track: first_track, direction: :prev)
      expect(result).to eq(first_track)
    end

    it 'does not wrap backward to the last track when moving prev from the first track' do
      result = controller.send(:select_track, current_track: first_track, direction: :prev)
      expect(result).not_to eq(last_track)
    end
  end

  describe 'JSON actions' do
    let(:artist) { create(:artist, title: 'Test Artist') }
    let(:release) { create(:release, artist:, title: 'Test Release') }
    let!(:first_track) { create(:track, release:, title: 'First Track', pos: 1) }
    let!(:last_track) { create(:track, release:, title: 'Last Track', pos: 2) }

    before do
      [first_track, last_track].each do |track|
        track.audio_file.attach(io: StringIO.new('fake audio'), filename: "#{track.title}.mp3")
      end
    end

    it 'wraps to the first track of the release on next_track from the last track' do
      session[:current_track_id] = last_track.id

      get :next_track, format: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('track', 'id')).to eq(first_track.id)
    end

    it 'stays on the first track on previous_track from the first track' do
      session[:current_track_id] = first_track.id

      get :previous_track, format: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('track', 'id')).to eq(first_track.id)
    end
  end
end