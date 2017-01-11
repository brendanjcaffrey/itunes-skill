class CustomIntents
  def initialize(db)
    @db = db
  end

  def on_play(request, builder)
    type, value = request.slots.first unless request.slots.nil?
    tracks = []

    case type
    when 'artist'   ; tracks = Library.get_tracks_for_artist_matching(value)
    when 'genre'    ; tracks = Library.get_tracks_for_genre_matching(value)
    when 'song'     ; tracks = Library.get_tracks_for_song_matching(value)
    when 'album'    ; tracks = Library.get_tracks_for_album_matching(value)
    else
      if type == 'playlist'
        playlist = Library.get_playlist_matching_term(value)
      else
        playlist = Library.get_library_playlist
        if playlist.nil?
          builder.add_plain_text_speech('I\'m having problems finding your library playlist')
          return
        end
      end

      tracks = Library.get_first_five_tracks_from_playlist(playlist)
      EnqueueFullPlaylistJob.perform_async(request.user_id, playlist, tracks.count)
    end

    if tracks.empty?
      builder.add_plain_text_speech("I couldn't find any #{type}s matching #{value}")
      return
    end

    builder.add_plain_text_speech('OK')
    @db.create_or_replace_user_playlist(request.user_id, tracks)

    track_id = tracks.first
    offset_in_milliseconds = Library.get_start_milliseconds_for_track_id(track_id)
    @db.update_offset(request.user_id, offset_in_milliseconds)
    builder.add_play_directive(request.user_id, track_id, offset_in_milliseconds)
  end
end
