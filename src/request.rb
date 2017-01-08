class Request
  attr_reader :user_id, :request_type, :offset_in_milliseconds, :token

  def self.extract_from_request_body(body)
    return new(nil, nil, nil, nil, nil) if body.empty?

    request = JSON.parse(body)
    if request.has_key?('session')
      app_id = request['session']['application']['applicationId']
      user_id = request['session']['user']['userId']
    else
      app_id = request['context']['System']['application']['applicationId']
      user_id = request['context']['System']['user']['userId']
    end

    request_type = request['request']['type']
    if request_type == 'IntentRequest'
      request_type = request['request']['intent']['name']
    elsif /AudioPlayer\..+/ === request_type
      # nop
    else
      request_type = nil
    end

    if request.has_key?('context') && request['context'].has_key?('AudioPlayer')
      offset_in_milliseconds = request['context']['AudioPlayer']['offsetInMilliseconds']
      token = request['context']['AudioPlayer']['token']
    else
      offset_in_milliseconds = 0
      token = nil
    end

    new(app_id, user_id, request_type, offset_in_milliseconds, token)
  end

  def initialize(app_id, user_id, request_type, offset_in_milliseconds, token)
    @app_id = app_id
    @request_type = request_type
    @user_id = user_id
    @offset_in_milliseconds = offset_in_milliseconds
    @token = token
  end

  def valid?
    @app_id == Secrets::EXPECTED_APP_ID && !@request_type.nil?
  end
end
