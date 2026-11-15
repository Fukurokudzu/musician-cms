require 'rails_helper'
require 'fileutils'
require 'tmpdir'

RSpec.describe Library do
  let(:root) { Dir.mktmpdir }

  after { FileUtils.remove_entry(root) if File.directory?(root) }

  describe 'with a populated library' do
    before do
      FileUtils.mkdir_p(File.join(root, 'First Artist'))
      FileUtils.mkdir_p(File.join(root, 'Second Artist'))
      File.write(File.join(root, 'loose-file.mp3'), 'audio')
    end

    it 'returns the artist folders' do
      library = described_class.new(root)

      expect(library.path).to eq(root)
      expect(library.artist_folders.keys).to contain_exactly('First Artist', 'Second Artist')
      expect(library.artist_folders.values).to all(start_with(root))
    end

    it 'ignores hidden folders' do
      FileUtils.mkdir_p(File.join(root, '.Trash'))

      expect(described_class.new(root).artist_folders.keys).not_to include('.Trash')
    end
  end

  describe 'with a broken library' do
    it 'raises when the path does not exist' do
      expect { described_class.new('/no/such/library') }
        .to raise_error(RuntimeError, /path not found/)
    end

    it 'raises when the library has no artist folders' do
      expect { described_class.new(root) }
        .to raise_error(RuntimeError, /No artist folders found/)
    end

    it 'raises when the library only contains hidden folders' do
      FileUtils.mkdir_p(File.join(root, '.hidden'))

      expect { described_class.new(root) }
        .to raise_error(RuntimeError, /No artist folders found/)
    end

    it 'raises when the library only contains files' do
      File.write(File.join(root, 'not-a-folder.mp3'), 'audio')

      expect { described_class.new(root) }
        .to raise_error(RuntimeError, /No artist folders found/)
    end
  end
end
