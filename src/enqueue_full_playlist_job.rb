class EnqueueFullPlaylistJob
  include SuckerPunch::Job

  def perform(user_id, playlist, enqueued_tracks_count)
    tracks = Library.get_tracks_from_playlist(playlist)
    new_tracks = tracks[enqueued_tracks_count..-1]
    Database.new.append_tracks(user_id, new_tracks)
  end
end
