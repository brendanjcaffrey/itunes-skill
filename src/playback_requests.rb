class PlaybackRequests
  def initialize(db)
    @db = Database.new
  end

  def on_started(request, builder)
    current_track_id = @db.get_current_track_and_offset(request.user_id).track_id

    if request.token == current_track_id
      builder.clear_response
      return
    end

    next_track_id = @db.get_next_track(request.user_id)
    if request.token == next_track_id
      @db.set_is_next_track_enqueued(request.user_id, false)
      @db.get_next_track_and_update_playlist(request.user_id)
      Library.add_play_for_track_id(current_track_id)
    end

    builder.clear_response
  end

  def on_finished(request, builder)
    builder.clear_response
  end

  def on_stopped(request, builder)
    builder.clear_response
  end

  def on_nearly_finished(request, builder)
    current_track_id = @db.get_current_track_and_offset(request.user_id).track_id
    if request.token != current_track_id
      builder.clear_response
      return
    end

    if @db.is_next_track_enqueued?(request.user_id)
      builder.clear_response
      return
    end

    next_track_id = @db.get_next_track(request.user_id)
    offset_in_milliseconds = Library.get_start_milliseconds_for_track_id(next_track_id)
    builder.add_enqueue_directive(request.user_id, next_track_id, current_track_id, offset_in_milliseconds)
    @db.set_is_next_track_enqueued(request.user_id, true)
  end

  def on_failed(request, builder)
    builder.clear_response
  end
end
