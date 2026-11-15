require 'rails_helper'

RSpec.describe ShortCodeLookup do
  let(:lookup) { Class.new { include ShortCodeLookup }.new }

  def resolve(scope, param)
    lookup.send(:find_short_codeable!, public_scope: scope, param:)
  end

  it 'resolves a public record by its short code' do
    artist = create(:artist)

    expect(resolve(Artist.active, artist.external_id)).to eq(artist)
  end

  it 'resolves the hidden sibling to RecordNotFound instead of a wrong record' do
    artist = create(:artist, soft_deleted: true)

    expect { resolve(Artist.active, artist.external_id) }
      .to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'refuses a model that is not short-codeable' do
    expect { resolve(AuditEvent.all, param: 'abcdefgh') }
      .to raise_error(ArgumentError, /ShortCodeable/)
  end
end
