require_relative '../lib/server'
require_relative '../cfg/server'

require_relative '../lib/mvc'
require_relative '../lib/delegate'

class SocketPlugin < Plugin
	def initAllServices
		regService SocketService, SocketService
	end

	def onStartup
	end

	def onUpdate
	end
end

class SocketService
	Inject(:application, Application)
	Inject(:onInject)

	def initialize
		@socket = SocketClient.new *ServerIP::CENTER, CenterHandler
		rescue Errno::ECONNREFUSED
		p $!
		sleep(1)
		retry
	end
	def send_packet packet
		packet.svrId = ServerID::GATE
		@socket.send_packet packet
	end
	private def onInject
		@socket.instance_variable_set(:@application, @application)
	end
end

module CenterHandler include SocketHandler
	def on_connect
		send_packet Packet.control ControlMsgID::SET_ID, ServerID::LOGIC
	end

	def on_disconnect
		$stdout.puts "on_disconnect"
	end

	def on_packet packet
		name = PacketMsgID.findName(packet.msgId)
		@application.notify(name, packet)
	end
end

module PacketMsgID
	@dict = {}
	def self.add name, id, svrId
		raise if @dict.any? { |key, value| key == id || value[0] == name }
		@dict[id] = [name, ServerID.const_get(svrId)]
	end
	def self.findName id
		@dict[id][0]
	end
	def self.findSvrId id
		return nil unless info = @dict[id]
		return info[1]
	end
end

module PacketHandler include DelegateMixin
	Inject(:socketService, SocketService)
	delegate :send_packet, :@socketService
end