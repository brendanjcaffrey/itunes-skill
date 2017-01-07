class CustomIntents
  def self.on_play(request, builder)
    # update the database
    tracks = Library.get_tracks_from_playlist_matching('!Listening')
    Database.new.create_or_replace_user_playlist(request.user_id, tracks)

    # start playing
    builder.add_plain_text_speech('OK')

    track_id = tracks.first
    offset_in_milliseconds = Library.get_start_milliseconds_for_track_id(track_id)
    builder.add_play_directive(request.user_id, track_id, offset_in_milliseconds)
  end
end
