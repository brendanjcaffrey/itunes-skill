require 'json'
require 'sinatra/base'
require 'sqlite3'
require 'time'
require 'sucker_punch'

require_relative 'control_intents.rb'
require_relative 'custom_intents.rb'
require_relative 'database.rb'
require_relative 'dispatcher.rb'
require_relative 'enqueue_full_playlist_job.rb'
require_relative 'library.rb'
require_relative 'playback_requests.rb'
require_relative 'request.rb'
require_relative 'response_builder.rb'
require_relative 'secrets.rb'

class Server < Sinatra::Base
  configure do
    set :bind, Secrets::SOCK
    set :host_authorization, { permitted_hosts: [Secrets::DOMAIN] }

    mime_type :mp3, 'audio/mpeg'
    mime_type :mp4, 'audio/mp4'
    mime_type :m4a, 'audio/mp4'
    mime_type :aif, 'audio/aif'
    mime_type :aiff, 'audio/aif'
    mime_type :wav, 'audio/wav'

    Database.create_tables
  end

  get '/tracks/*/*' do
    user_id, track_id = params['splat']
    raise Sinatra::NotFound if !Database.new.is_valid_user?(user_id)

    location = Library.get_location_for_track_id(track_id)
    ext = location.split('.').last
    send_file(location, type: ext, last_modified: Time.now.httpdate)
  end

  post '/itunes' do
    body = request.body.read
    request = Request.extract_from_request_body(body)
    raise Sinatra::NotFound unless request.valid?

    response = Dispatcher.dispatch_request(request)
    halt unless response

    content_type :json
    response.to_json
  end
end
