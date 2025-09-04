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
    artists_to_remove = @existing_artists.reject { |title| @artist_folders.key?(title) }
    Artist.where(title: artists_to_remove).destroy_all
  end
end
