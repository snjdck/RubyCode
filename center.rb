for name in %w[ioc mvc reactor]
	$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'gems', name, 'lib'))
end

require 'reactor'
require_relative 'cfg/server'

$client_dict = {}

module ServerHandler include SocketHandler
	def on_disconnect
		$client_dict.delete @svrId if @svrId
	end

	def on_packet packet
		sock = $client_dict[packet.svrId]
		return unless sock
		sock.send_packet packet
	end

	def on_control packet
		if packet.msgId == ControlMsgID::SET_ID
			@svrId = packet.svrId
			$client_dict[@svrId] = self
		else
			on_packet packet
		end
	end
end

SocketServer.new *ServerIP::CENTER, ServerHandler

$selector.run