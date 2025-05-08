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
end