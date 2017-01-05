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
    tell application "iTunes"
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

  PLAYLIST_TRACKS = <<-SCRIPT
    tell application "iTunes"
      set output to ""
      set thisPlaylist to some playlist whose persistent id is "%s"

      #{SET_DELIMS}
      repeat with thisTrack in file tracks of thisPlaylist
        set output to output & persistent id of thisTrack & "\n"
      end repeat
      #{RESET_DELIMS}

      output
    end tell
  SCRIPT

  TRACK_LOCATION = <<-SCRIPT
    tell application "iTunes"
      set thisTrack to some track whose persistent id is "%s"
      set output to location of thisTrack as text
      output
    end tell
  SCRIPT

  INCREMENT_PLAYED_COUNT = <<-SCRIPT
    tell application "iTunes"
      set thisTrack to some track whose persistent ID is "%s"
      set played count of thisTrack to (played count of thisTrack) + 1
    end tell
  SCRIPT

  def self.get_tracks_from_playlist_matching(term)
    playlist = get_matching_playlist(term)
    return [] unless playlist

    get_tracks_for_playlist(playlist)
  end

  def self.get_location_for_track_id(id)
    # location looks like "Macintosh HD:Users:Brendan:Music:iTunes:iTunes Music:artist:album:song.mp3"
    # so we turn the : into / and remove the drive name
    `osascript -e '#{TRACK_LOCATION % id}'`.chomp.gsub(':', '/').gsub(/^.+?\//, '/')
  end

  def self.add_play_for_track_id(id)
    `osascript -e '#{INCREMENT_PLAYED_COUNT % id}'`
  end

  private

  def self.get_matching_playlist(term)
    playlists = get_all_matching_playlists(term)
    filter_playlists(playlists, term)
  end

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

  def self.get_tracks_for_playlist(playlist)
    `osascript -e '#{PLAYLIST_TRACKS % playlist.id}'`.split("\n")
  end

  def self.get_all_matching_playlists(term)
    output = `osascript -e '#{PLAYLISTS % term}'`
    output.split("\n").map { |line| Playlist.new(*line.split(' ', 2)) }
  end
end
