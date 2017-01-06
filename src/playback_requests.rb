class PlaybackRequests
  def self.on_started(request, builder)
    builder.clear_response
  end

  def self.on_finished(request, builder)
    builder.clear_response
  end

  def self.on_stopped(request, builder)
    builder.clear_response
  end

  def self.on_nearly_finished(request, builder)
    builder.clear_response
  end

  def self.on_failed(request, builder)
    builder.clear_response
  end
end
