module WebSocket
	module Writer
		def create_packet(data)
			opCode = 1
			payloadLen = data.bytesize
			packet = [0x80 | opCode, payloadLen].pack('C2') + data
			writePayloadLen(packet, payloadLen)
			packet
		end

		def writePayloadLen(packet, payloadLen)
			if payloadLen < 126
			elsif payloadLen < 0x10000
				packet[1] = [126, payloadLen].pack('Cn')
			else
				packet[1] = [127, 0, payloadLen].pack('CNN')
			end
		end
	end
end