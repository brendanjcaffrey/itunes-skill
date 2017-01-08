class CustomIntents
  def initialize(db)
    @db = db
  end

  def on_play(request, builder)
    # update the database
    tracks = Library.get_tracks_from_playlist_matching('!New').shuffle
    @db.create_or_replace_user_playlist(request.user_id, tracks)

    # start playing
    builder.add_plain_text_speech('OK')

    track_id = tracks.first
    offset_in_milliseconds = Library.get_start_milliseconds_for_track_id(track_id)
    @db.update_offset(request.user_id, offset_in_milliseconds)
    builder.add_play_directive(request.user_id, track_id, offset_in_milliseconds)
  end
end
