class ControlIntents
  def self.on_cancel(request, builder)
    on_stop(request, builder)
  end

  def self.on_loop(request, builder, enabled)
    on_unsupported(builder)
  end

  def self.on_next(request, builder)
    on_unsupported(builder)
  end

  def self.on_pause(request, builder)
    on_stop(request, builder) # TODO store time in DB and resume in appropriate place
  end

  def self.on_previous(request, builder)
    on_unsupported(builder)
  end

  def self.on_repeat(request, builder)
    on_unsupported(builder)
  end

  def self.on_resume(request, builder)
    on_unsupported(builder)
  end

  def self.on_shuffle(request, builder, enabled)
    on_unsupported(builder)
  end

  def self.on_start_over(request, builder)
    on_unsupported(builder)
  end

  def self.on_stop(request, builder)
    builder.add_stop_directive()
  end

  private

  def self.on_unsupported(builder)
    builder.add_plain_text_speech('I don\'t support that right now')
  end
end
