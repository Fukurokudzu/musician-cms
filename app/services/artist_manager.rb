class ArtistManager
  def initialize(artist_folders)
    @artist_folders = artist_folders
    @existing_artists = Artist.pluck(:title).to_set
  end

  def create_artists
    @artist_folders.each_key do |artist|
      Artist.find_or_create_by(title: artist)
    end

    remove_deleted_artists
  end

  def remove_deleted_artists
    @existing_artists.each do |artist_title|
      unless @artist_folders.key?(artist_title)
        artist = Artist.find_by(title: artist_title)
        artist&.destroy
      end
    end
  end
end
