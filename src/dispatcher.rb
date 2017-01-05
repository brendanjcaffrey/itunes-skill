class Dispatcher
  def self.dispatch_request(request)
    builder = ResponseBuilder.new

    case request.request_type
    when 'Play' ; CustomIntents.on_play(request, builder)

    # built in playback control intents
    when 'AMAZON.CancelIntent'     ; ControlIntents.on_cancel(request, builder)
    when 'AMAZON.LoopOffIntent'    ; ControlIntents.on_loop(request, builder, false)
    when 'AMAZON.LoopOnIntent'     ; ControlIntents.on_loop(request, builder, true)
    when 'AMAZON.NextIntent'       ; ControlIntents.on_next(request, builder)
    when 'AMAZON.PauseIntent'      ; ControlIntents.on_pause(request, builder)
    when 'AMAZON.PreviousIntent'   ; ControlIntents.on_previous(request, builder)
    when 'AMAZON.RepeatIntent'     ; ControlIntents.on_repeat(request, builder)
    when 'AMAZON.ResumeIntent'     ; ControlIntents.on_resume(request, builder)
    when 'AMAZON.ShuffleOffIntent' ; ControlIntents.on_shuffle(request, builder, false)
    when 'AMAZON.ShuffleOnIntent'  ; ControlIntents.on_shuffle(request, builder, true)
    when 'AMAZON.StartOverIntent'  ; ControlIntents.on_start_over(request, builder)
    when 'AMAZON.StopIntent'       ; ControlIntents.on_stop(request, builder)

    # audio player requests
    when 'AudioPlayer.PlaybackStarted'        ; PlaybackRequests.on_started(request, builder)
    when 'AudioPlayer.PlaybackFinished'       ; PlaybackRequests.on_finished(request, builder)
    when 'AudioPlayer.PlaybackStopped'        ; PlaybackRequests.on_stopped(request, builder)
    when 'AudioPlayer.PlaybackNearlyFinished' ; PlaybackRequests.on_nearly_finished(request, builder)
    when 'AudioPlayer.PlaybackFailed'         ; PlaybackRequests.on_failed(request, builder)

    # unknown
    else
      puts 'Unable to route request:'
      puts request.inspect
      return false
    end

    builder.response
  end
end
