require_relative 'lib/server'
require_relative 'cfg/server'
require_relative 'lib/counter'

module ClientHandler include SocketHandler

	def on_connect
		$stdout.puts "on_connect"
	end
	def on_disconnect
		$stdout.puts "on_disconnect"
	end
	def on_packet packet
		$stdout.puts packet.msgData
	end
end

client = SocketClient.new *ServerIP::GATE, ClientHandler
packet = Packet.create 1, 'i love you'

timer = Counter.new 1

$selector.run 0.01 do
	timer.update { client.send_packet packet }
end
