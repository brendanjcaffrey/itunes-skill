task :serve do
  require_relative 'src/server.rb'
  Server.run!
end

task :daemonize do
  Process.daemon true
  require_relative 'src/server.rb'
  Server.run!
end
