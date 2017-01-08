class Dispatcher
  def self.dispatch_request(request)
    builder  = ResponseBuilder.new
    database = Database.new

    case request.request_type
    when 'Play' ; CustomIntents.new(database).on_play(request, builder)

    # built in playback control intents
    when 'AMAZON.CancelIntent'     ; ControlIntents.new(database).on_cancel(request, builder)
    when 'AMAZON.LoopOffIntent'    ; ControlIntents.new(database).on_loop(request, builder, false)
    when 'AMAZON.LoopOnIntent'     ; ControlIntents.new(database).on_loop(request, builder, true)
    when 'AMAZON.NextIntent'       ; ControlIntents.new(database).on_next(request, builder)
    when 'AMAZON.PauseIntent'      ; ControlIntents.new(database).on_pause(request, builder)
    when 'AMAZON.PreviousIntent'   ; ControlIntents.new(database).on_previous(request, builder)
    when 'AMAZON.RepeatIntent'     ; ControlIntents.new(database).on_repeat(request, builder)
    when 'AMAZON.ResumeIntent'     ; ControlIntents.new(database).on_resume(request, builder)
    when 'AMAZON.ShuffleOffIntent' ; ControlIntents.new(database).on_shuffle(request, builder, false)
    when 'AMAZON.ShuffleOnIntent'  ; ControlIntents.new(database).on_shuffle(request, builder, true)
    when 'AMAZON.StartOverIntent'  ; ControlIntents.new(database).on_start_over(request, builder)
    when 'AMAZON.StopIntent'       ; ControlIntents.new(database).on_stop(request, builder)

    # audio player requests
    when 'AudioPlayer.PlaybackStarted'        ; PlaybackRequests.new(database).on_started(request, builder)
    when 'AudioPlayer.PlaybackFinished'       ; PlaybackRequests.new(database).on_finished(request, builder)
    when 'AudioPlayer.PlaybackStopped'        ; PlaybackRequests.new(database).on_stopped(request, builder)
    when 'AudioPlayer.PlaybackNearlyFinished' ; PlaybackRequests.new(database).on_nearly_finished(request, builder)
    when 'AudioPlayer.PlaybackFailed'         ; PlaybackRequests.new(database).on_failed(request, builder)

    # unknown
    else
      puts 'Unable to route request:'
      puts request.inspect
      return nil
    end

    builder.response
  end
end
