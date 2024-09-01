class ArtistManager
  def initialize(artist_folders)
    @artist_folders = artist_folders
  end

  def create_artists
    @artist_folders.each_key do |artist|
      Artist.find_or_create_by(title: artist)
    end
  end
end