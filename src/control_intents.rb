class ControlIntents
  def initialize(db)
    @db = db
  end

  def on_loop(request, builder, enabled)
    on_unsupported(builder)
  end

  def on_next(request, builder)
    track_id = @db.get_next_track_and_update_playlist(request.user_id)
    change_to_track(request, builder, track_id)
  end

  def on_pause(request, builder)
    stop_playing(request, builder, request.offset_in_milliseconds)
    builder.add_clear_enqueued_and_stop_directives
  end

  def on_previous(request, builder)
    track_id = @db.get_previous_track_and_update_playlist(request.user_id)
    change_to_track(request, builder, track_id)
  end

  def on_repeat(request, builder)
    on_unsupported(builder)
  end

  def on_resume(request, builder)
    track_and_offset = @db.get_current_track_and_offset(request.user_id)
    builder.add_play_directive(request.user_id, track_and_offset.track_id, track_and_offset.offset_in_milliseconds)
  end

  def on_shuffle(request, builder, enabled)
    on_unsupported(builder)
  end

  def on_start_over(request, builder)
    track_and_offset = @db.get_current_track_and_offset(request.user_id)
    change_to_track(request, builder, track_and_offset.track_id)
  end

  def on_stop(request, builder)
    track_id = @db.get_current_track_and_offset(request.user_id).track_id
    stop_playing(request, builder, Library.get_start_milliseconds_for_track_id(track_id))
    builder.add_clear_all_directive
  end

  alias_method :on_cancel, :on_stop

  private

  def on_unsupported(builder)
    builder.add_plain_text_speech('I don\'t support that right now')
  end

  def change_to_track(request, builder, track_id)
    @db.set_is_next_track_enqueued(request.user_id, false)
    offset_in_milliseconds = Library.get_start_milliseconds_for_track_id(track_id)
    @db.update_offset(request.user_id, offset_in_milliseconds)

    builder.add_play_directive(request.user_id, track_id, offset_in_milliseconds)
  end

  def stop_playing(request, builder, offset_in_milliseconds)
    @db.set_is_next_track_enqueued(request.user_id, false)
    @db.update_offset(request.user_id, offset_in_milliseconds)
  end
end
