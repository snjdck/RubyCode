require_relative 'lib/counter'
require_relative 'plugins/socket'
require_relative 'plugins/test'

application = Application.new
application.regPlugin SocketPlugin
application.regPlugin TestPlugin
application.startup

timer = Counter.new 1

$selector.run 0.5 do
	timer.update { application.onUpdate }
end