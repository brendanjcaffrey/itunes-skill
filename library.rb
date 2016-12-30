module AppleScript
  SET_DELIMS = <<-SCRIPT
    set AppleScript'"'"'s text item delimiters to {}
    set oldDelims to AppleScript'"'"'s text item delimiters
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
        set playlistId to id of thisPlaylist
        if "%s" is in playlistName then
          set output to output & playlistId & " " & playlistName & "\n"
        end if
      end repeat
      #{RESET_DELIMS}

      output
    end tell
  SCRIPT
end

module Library
  Playlist = Struct.new(:id, :name)
  class Playlists
    def get_matching(term)
      playlists = get_all_matching(term)

      return nil if playlists.count == 0
      return playlists.first if playlists.count == 1

      exact = playlists.select { |playlist| playlist.name.downcase == term.downcase }
      return exact.first if exact.count != 0

      playlists.first
    end

    private

    def get_all_matching(term)
      output = `osascript -e '#{AppleScript::PLAYLISTS % term}'`
      output.split("\n").map { |line| Playlist.new(*line.split(' ', 2)) }
    end
  end
end
