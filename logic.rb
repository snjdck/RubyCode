$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'gems', 'ioc', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'gems', 'mvc', 'lib'))

require 'injector'
require 'mvc'

require_relative 'lib/counter'
require_relative 'plugins/socket'
require_relative 'plugins/test'

application = MVC::Application.new
application.regModule SocketPlugin
application.regModule TestPlugin
application.startup

timer = Counter.new 1

$selector.run 0.5 do
	timer.update { application.onUpdate }
end