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
    @response[:response][:directives] = [{
      type: 'AudioPlayer.Play',
      playBehavior: 'REPLACE_ALL',
      audioItem: {
        stream: {
          url: "https://#{Secrets::DOMAIN}/tracks/#{user_id}/#{track_id}",
          token: track_id,
          offsetInMilliseconds: offset_in_milliseconds
        }
      }
    }]
  end

  def add_enqueue_directive(user_id, track_id, previous_track_id, offset_in_milliseconds = 0)
    @response[:response][:directives] = [{
      type: 'AudioPlayer.Play',
      playBehavior: 'ENQUEUE',
      audioItem: {
        stream: {
          url: "https://#{Secrets::DOMAIN}/tracks/#{user_id}/#{track_id}",
          token: track_id,
          expectedPreviousToken: previous_track_id,
          offsetInMilliseconds: offset_in_milliseconds
        }
      }
    }]
  end

  def add_clear_all_directive
    @response[:response][:directives] = [{
      type: 'AudioPlayer.ClearQueue',
      clearBehavior: 'CLEAR_ALL'
    }]
  end

  def add_clear_enqueued_and_stop_directives
    @response[:response][:directives] = [{
      type: 'AudioPlayer.ClearQueue',
      clearBehavior: 'CLEAR_ENQUEUED'
    }, {
      type: 'AudioPlayer.Stop'
    }]
  end

  def clear_response
    @response = nil
  end
end
