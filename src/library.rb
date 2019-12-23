class Library
  Playlist = Struct.new(:id, :name)
  SET_DELIMS = <<-SCRIPT
    set oldDelims to AppleScript'"'"'s text item delimiters
    set AppleScript'"'"'s text item delimiters to {}
  SCRIPT

  RESET_DELIMS = <<-SCRIPT
    set AppleScript'\"'\"'s text item delimiters to oldDelims
  SCRIPT

  PLAYLISTS = <<-SCRIPT
    tell application "Music"
      set output to ""
      set playlistCount to count of playlists

      #{SET_DELIMS}
      repeat with index from 1 to playlistCount
        set thisPlaylist to playlists index
        set playlistName to name of thisPlaylist
        set playlistId to persistent id of thisPlaylist
        if "%s" is in playlistName then
          set output to output & playlistId & " " & playlistName & "\n"
        end if
      end repeat
      #{RESET_DELIMS}

      output
    end tell
  SCRIPT

  LIBRARY_PLAYLIST = <<-SCRIPT
    tell application "Music"
      set output to ""
      set playlistCount to count of playlists

      #{SET_DELIMS}
      repeat with i from 1 to playlistCount
        set thisPlaylist to playlist i
        set playlistKind to special kind of thisPlaylist as string
        if playlistKind is equal to "Music" then
          set playlistId to persistent id of thisPlaylist
          set playlistName to name of thisPlaylist
          set output to playlistId & " " & playlistName
        end if
      end repeat
      #{RESET_DELIMS}

      output
    end tell
  SCRIPT

  FIRST_FIVE_PLAYLIST_TRACKS = <<-SCRIPT
    tell application "Music"
      set output to ""
      set thisPlaylist to some playlist whose persistent id is "%s"
      set tracksCount to count of file tracks of thisPlaylist
      set loopCount to 5
      if tracksCount < 5 then
        set loopCount to tracksCount
      end if

      #{SET_DELIMS}
      repeat with i from 1 to loopCount
        set thisTrack to file track i of thisPlaylist
        set output to output & persistent id of thisTrack & "\n"
      end repeat
      #{RESET_DELIMS}

      output
    end tell
  SCRIPT

  PLAYLIST_TRACKS = <<-SCRIPT
    tell application "Music"
      set output to ""
      set thisPlaylist to some playlist whose persistent id is "%s"
      set theTracks to (every file track of thisPlaylist)

      #{SET_DELIMS}
      repeat with theTrack in theTracks
        set output to output & persistent id of theTrack & "\n"
      end repeat
      #{RESET_DELIMS}

      output
    end tell
  SCRIPT

  FILTER_TRACKS = <<-SCRIPT
    tell application "Music"
      set output to ""
      set theTracks to (every file track of playlist "Library" whose %s contains "%s")

      #{SET_DELIMS}
      repeat with theTrack in theTracks
        set output to output & persistent id of theTrack & "\n"
      end repeat
      #{RESET_DELIMS}

      output
    end tell
  SCRIPT

  ARTIST_TRACKS = FILTER_TRACKS % ['artist', '%s']
  ALBUM_TRACKS  = FILTER_TRACKS % ['album',  '%s']
  SONG_TRACKS   = FILTER_TRACKS % ['name',   '%s']
  GENRE_TRACKS  = FILTER_TRACKS % ['genre',  '%s']

  TRACK_LOCATION = <<-SCRIPT
    tell application "Music"
      set thisTrack to some track whose persistent id is "%s"
      set output to location of thisTrack as text
      output
    end tell
  SCRIPT

  TRACK_START_TIME = <<-SCRIPT
    tell application "Music"
      set thisTrack to some track whose persistent id is "%s"
      set output to start of thisTrack
      output
    end tell
  SCRIPT

  INCREMENT_PLAYED_COUNT = <<-SCRIPT
    tell application "Music"
      set thisTrack to some track whose persistent ID is "%s"
      set played count of thisTrack to (played count of thisTrack) + 1
    end tell
  SCRIPT

  def self.get_playlist_matching_term(term)
    playlists = get_all_matching_playlists(term)
    filter_playlists(playlists, term)
  end

  def self.get_library_playlist
    output = `osascript -e '#{LIBRARY_PLAYLIST}'`
    Playlist.new(*output.chomp.split(' ', 2))
  end

  def self.get_first_five_tracks_from_playlist(playlist)
    `osascript -e '#{FIRST_FIVE_PLAYLIST_TRACKS % playlist.id}'`.split("\n")
  end

  def self.get_tracks_from_playlist(playlist)
    `osascript -e '#{PLAYLIST_TRACKS % playlist.id}'`.split("\n")
  end

  def self.get_tracks_for_artist_matching(artist)
    `osascript -e '#{ARTIST_TRACKS % artist}'`.split("\n")
  end

  def self.get_tracks_for_album_matching(album)
    `osascript -e '#{ALBUM_TRACKS % album}'`.split("\n")
  end

  def self.get_tracks_for_song_matching(song)
    `osascript -e '#{SONG_TRACKS % song}'`.split("\n")
  end

  def self.get_tracks_for_genre_matching(genre)
    `osascript -e '#{GENRE_TRACKS % genre}'`.split("\n")
  end

  def self.get_location_for_track_id(id)
    # location looks like "Macintosh HD:Users:Brendan:Music:iTunes:iTunes Music:artist:album:song.mp3"
    # so we turn the : into / and remove the drive name
    `osascript -e '#{TRACK_LOCATION % id}'`.chomp.gsub(':', '/').gsub(/^.+?\//, '/')
  end

  def self.get_start_milliseconds_for_track_id(id)
    # it's returned in seconds
    (`osascript -e '#{TRACK_START_TIME % id}'`.chomp.to_f * 1000.0).to_i
  end

  def self.add_play_for_track_id(id)
    `osascript -e '#{INCREMENT_PLAYED_COUNT % id}'`
  end

  private

  def self.filter_playlists(playlists, term)
    return nil if playlists.count == 0

    # if there's only one match, use that
    return playlists.first if playlists.count == 1

    # try to find an exact match
    exact = playlists.select { |playlist| playlist.name.downcase == term.downcase }
    return exact.first if exact.count != 0

    # otherwise, give up and use the first one
    playlists.first
  end

  def self.get_all_matching_playlists(term)
    output = `osascript -e '#{PLAYLISTS % term}'`
    output.split("\n").map { |line| Playlist.new(*line.split(' ', 2)) }
  end
end
