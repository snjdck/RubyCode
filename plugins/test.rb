

require_relative '../cfg/server'
require_relative '../cfg/packet'

class TestPlugin < MVC::Module
	def initAllServices
	end

	def onStartup
		@application.regCmd :TEST, TestHandler.new
	end
end

class TestHandler
	include PacketHandler

	def call packet
		p "fuck ,i am run"
		send_packet packet
		return
		newPacket = Packet.new
		newPacket.type = Packet::TYPE_CONTROL
		newPacket.msgId = ControlMsgID::FORCE_CLOSE
		newPacket.usrId = packet.usrId
		send_packet newPacket
	end
end