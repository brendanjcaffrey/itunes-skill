class CustomIntents
  def self.on_play(request, builder)
    builder.add_plain_text_speech('hello')
  end
end
