class Packet

	TYPE_DEFAULT = 0
	TYPE_CONTROL = 1

	Format = 'n4Ca*'

	class << self
		def control msgId, svrId
			packet = new
			packet.type = TYPE_CONTROL
			packet.msgId = msgId
			packet.svrId = svrId
			packet
		end

		def create msgId, msgData
			packet = new
			packet.msgId = msgId
			packet.msgData = msgData
			packet
		end

		def parse data
			return if data.bytesize < @@headSize
			packetSize = data.unpack('n')[0]
			return if data.bytesize < packetSize
			buffer = data[0, packetSize]
			data[0, packetSize] = ''
			new buffer.unpack(Format)
		end

		private
		def attr name, index
			define_method name do
				@buffer[index]
			end
			define_method :"#{name}=" do |value|
				@buffer[index] = value
			end
		end
	end

	@@headSize = 9
	
	attr :msgId,  1
	attr :usrId,  2
	attr :svrId,  3
	attr :type ,  4
	attr :msgData,5

	def initialize(buffer=nil)
		@buffer = buffer || [0, 0, 0, 0, 0, nil]
	end

	def to_s
		@buffer[0] = @@headSize + (msgData ? msgData.bytesize : 0)
		@buffer.pack(Format)
	end

	def reply msgId, msgData
		packet = self.class.new
		packet.msgId = msgId
		packet.msgData = msgData
		packet.usrId = usrId
		packet
	end
end