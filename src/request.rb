class Request
  attr_reader :request_type

  def self.extract_from_request_body(body)
    return new(nil, nil) if body.empty?

    request = JSON.parse(body)
    app_id = request['session']['application']['applicationId']

    request_type = request['request']['type']
    if request_type == 'IntentRequest'
      request_type = request['request']['intent']['name']
    elsif /AudioPlayer\..+/ === request_type
      # nop
    else
      request_type = nil
    end

    new(app_id, request_type)
  end

  def initialize(app_id, request_type)
    @app_id = app_id
    @request_type = request_type
  end

  def valid?
    @app_id == Secrets::EXPECTED_APP_ID && !@request_type.nil?
  end
end
