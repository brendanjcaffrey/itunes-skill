require 'json'
require 'sinatra/base'
require 'sinatra/json'

require_relative 'control_intents.rb'
require_relative 'custom_intents.rb'
require_relative 'dispatcher.rb'
require_relative 'playback_requests.rb'
require_relative 'request.rb'
require_relative 'response_builder.rb'
require_relative 'secrets.rb'

class Server < Sinatra::Base
  configure do
    set :bind, '0.0.0.0'
    set :port, Secrets::PORT
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

  post '/itunes' do
    body = request.body.read
    request = Request.extract_from_request_body(body)
    halt unless request.valid?

    response = Dispatcher.dispatch_request(request)
    if response
      content_type :json
      json response
    else
      halt
    end
  end
end
