require 'json'
require 'sinatra/base'
require 'sinatra/json'
require 'sqlite3'

require_relative 'control_intents.rb'
require_relative 'custom_intents.rb'
require_relative 'database.rb'
require_relative 'dispatcher.rb'
require_relative 'library.rb'
require_relative 'playback_requests.rb'
require_relative 'request.rb'
require_relative 'response_builder.rb'
require_relative 'secrets.rb'

class Server < Sinatra::Base
  configure do
    set :bind, '0.0.0.0'
    set :port, Secrets::PORT

    mime_type :mp3, 'audio/mpeg'
    mime_type :mp4, 'audio/mp4'
    mime_type :m4a, 'audio/mp4'
    mime_type :aif, 'audio/aif'
    mime_type :aiff, 'audio/aif'
    mime_type :wav, 'audio/wav'

    Database.create_tables
  end

  # https://gist.github.com/TakahikoKawasaki/40ef0ab011b0a467bedf#file-sinatra-ssl-rb (see ./ssl/README)
  def self.run!
    super do |server|
      server.ssl = true
      server.ssl_options = {
        :cert_chain_file  => File.dirname(__FILE__) + '/../ssl/server.crt',
        :private_key_file => File.dirname(__FILE__) + '/../ssl/server.key',
        :verify_peer      => false
      }
    end
  end

  get '/tracks/*/*' do
    user_id, track_id = params['splat']
    raise Sinatra::NotFound if !Database.valid_user?(user_id)

    location = Library.get_location_for_track_id(track_id)
    ext = location.split('.').last
    send_file(location, type: ext)
  end

  post '/itunes' do
    body = request.body.read
    request = Request.extract_from_request_body(body)
    raise Sinatra::NotFound unless request.valid?

    response = Dispatcher.dispatch_request(request)
    if response
      content_type :json
      json response
    else
      halt
    end
  end
end
