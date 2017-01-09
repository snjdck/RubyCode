require 'reactor'

require_relative 'websocket/http_header'
require_relative 'websocket/reader'
require_relative 'websocket/writer'

class String
	def unpack1(format)
		unpack(format)[0]
	end
end

module WebSocketHandler include SocketHandlerBase
	include WebSocket::Reader
	include WebSocket::Writer

	def send_packet(data)
		send_raw(create_packet(data))
	end
end