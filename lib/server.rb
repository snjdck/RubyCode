require 'socket'
require_relative 'selector'

class SocketServer < TCPServer
	def initialize(host, port, handler)
		super(host, port)
		$selector.add_recv self
		@handler = handler
	end

	def on_recv
		sock = accept
		$selector.add_recv sock
		sock.extend(@handler).on_connect
	end
end

class SocketClient < TCPSocket
	def initialize(host, port, handler)
		super(host, port)
		$selector.add_recv self
		extend(handler).on_connect
	end
end
