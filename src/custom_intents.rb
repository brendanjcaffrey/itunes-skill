class CustomIntents
  def self.on_play(request, builder)
    # update the database
    tracks = Library.get_tracks_from_playlist_matching('!New')
    Database.new.create_or_replace_user_playlist(request.user_id, tracks)

    # start playing
    builder.add_plain_text_speech('OK')
    builder.add_play_directive(request.user_id, tracks.first)
  end
end
