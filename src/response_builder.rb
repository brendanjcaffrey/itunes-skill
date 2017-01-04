class ResponseBuilder
  attr_reader :response

  def initialize
    @response = {
      version: '2.0',
      response: {}
    }
  end

  def add_plain_text_speech(text)
    @response[:response][:outputSpeech] = {
      type: 'PlainText',
      text: text
    }
  end
end
