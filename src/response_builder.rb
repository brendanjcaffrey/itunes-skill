class ResponseBuilder
  attr_reader :response

  def initialize
    @response = {
      version: '2.0',
      response: {
        shouldEndSession: true
      }
    }
  end

  def add_plain_text_speech(text)
    @response[:response][:outputSpeech] = {
      type: 'PlainText',
      text: text
    }
  end

  def add_play_directive(user_id, track_id, offset_in_milliseconds = 0)
    @response[:response][:directives] ||= []
    @response[:response][:directives] << {
      type: 'AudioPlayer.Play',
      playBehavior: 'REPLACE_ALL',
      audioItem: {
        stream: {
          url: "https://#{Secrets::DOMAIN}/tracks/#{user_id}/#{track_id}",
          token: track_id,
          offsetInMilliseconds: offset_in_milliseconds
        }
      }
    }
  end

  def add_stop_directive
    @response[:response][:directives] ||= []
    @response[:response][:directives] << {
      type: 'AudioPlayer.Stop'
    }
  end

  def clear_response
    @response = nil
  end
end
