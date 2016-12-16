require_relative 'lib/server'
require_relative 'cfg/server'
require_relative 'cfg/packet'

$client_dict = {}

module ServerHandler include SocketHandler
	@@index = 0

	def nextUsrId
		usrId = @@index
		@@index += 1
		usrId
	end

	def on_connect
		@usrId = nextUsrId
		$client_dict[@usrId] = self
	end

	def on_disconnect
		$stdout.puts "on_disconnect"
		$client_dict.delete @usrId
	end

	def on_packet packet
		svrId = PacketMsgID.findSvrId(packet.msgId)
		return unless svrId
		packet.svrId = svrId
		packet.usrId = @usrId
		$center.send_packet packet
	end
end

module CenterHandler include SocketHandler
	def on_connect
		send_packet Packet.control ControlMsgID::SET_ID, ServerID::GATE
	end

	def on_disconnect
		$center = nil
	end

	def on_packet packet
		sock = $client_dict[packet.usrId]
		return unless sock
		sock.send_packet packet
	end

	def on_control packet
		case packet.msgId
		when ControlMsgID::FORCE_CLOSE
			sock = $client_dict[packet.usrId]
			return unless sock
			sock.close
		end
	end
end

$center = SocketClient.new *ServerIP::CENTER, CenterHandler
SocketServer.new *ServerIP::GATE, ServerHandler

$selector.run 0.01