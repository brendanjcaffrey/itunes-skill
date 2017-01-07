class ControlIntents
  def initialize
    @db = Database.new
  end

  def on_cancel(request, builder)
    on_stop(request, builder)
  end

  def on_loop(request, builder, enabled)
    on_unsupported(builder)
  end

  def on_next(request, builder)
    track_id = @db.get_next_track_and_update_playlist(request.user_id)
    builder.add_play_directive(request.user_id, track_id)
  end

  def on_pause(request, builder)
    builder.add_stop_directive
    @db.update_offset(request.user_id, request.offset_in_milliseconds)
  end

  def on_previous(request, builder)
    track_id = @db.get_previous_track_and_update_playlist(request.user_id)
    builder.add_play_directive(request.user_id, track_id)
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
    @db.update_offset(request.user_id, 0)
    on_resume(request, builder)
  end

  def on_stop(request, builder)
    builder.add_stop_directive
    @db.update_offset(request.user_id, 0)
  end

  private

  def on_unsupported(builder)
    builder.add_plain_text_speech('I don\'t support that right now')
  end
end
