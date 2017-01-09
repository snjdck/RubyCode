require 'digest'

module WebSocket
	module Reader
		RESPONSE_TEXT = [
			'HTTP/1.1 101 Switching Protocols',
			'connection: Upgrade',
			'upgrade: websocket',
			nil, "\r\n"]
		KEY_TAIL = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11'

		def on_parse
			if @has_upgrade then parse_data
			else parse_upgrade end
		end

		def parse_upgrade
			index = @buffer_recv.index("\r\n\r\n")
			return unless index
			header = HttpHeader.new(@buffer_recv[0, index])
			unless header.method == 'GET' && header['connection'] == 'Upgrade' && header['upgrade'] == 'websocket'
				close
				return
			end
			@buffer_recv[0, index+4] = ''
			key = header['sec-websocket-key'] + KEY_TAIL
			key = Digest::SHA1.base64digest(key)
			RESPONSE_TEXT[-2] = "sec-websocket-accept: #{key}"
			send_raw(RESPONSE_TEXT.join(RESPONSE_TEXT[-1]))
			@has_upgrade = true
		end

		def parse_data
			_begin = 0
			_end = @buffer_recv.size
			loop do
				break if _end - _begin < 2
				byte1, byte2 = @buffer_recv.unpack('C2')

				finFlag = byte1 >> 7 == 1
				opCode = byte1 & 0xF
				hasMask = byte2 >> 7 == 1
				payloadLen = byte2 & 0x7F
				
				headLen = calcHeadLen(hasMask, payloadLen)
				break if _end - _begin < headLen
				payloadLen = readPayloadLen(payloadLen, _begin)
				break if _end - _begin < headLen + payloadLen
				_begin += headLen

				decodePayload(_begin, payloadLen) if hasMask
				parsePayload(opCode, _begin, payloadLen)

				_begin += payloadLen
			end

			@buffer_recv[0, _begin] = '' if _begin > 0
		end

		def calcHeadLen(hasMask, payloadLen)
			headLen = 0
			if payloadLen < 126
				headLen = 2
			elsif payloadLen == 126
				headLen = 4
			else
				headLen = 10
			end
			headLen += 4 if hasMask
			headLen
		end

		def readPayloadLen(payloadLen, offset)
			if payloadLen < 126 then payloadLen
			elsif payloadLen == 126
				@buffer_recv[offset+2, 2].unpack1('n')
			else
				@buffer_recv[offset+6, 4].unpack1('N')
			end
		end

		def decodePayload(offset, payloadLen)
			mask = @buffer_recv[offset - 4, 4].unpack('C4')
			payloadLen.times do |i|
				index = offset + i
				value = @buffer_recv[index].unpack1('C')
				value ^= mask[i % 4]
				@buffer_recv[index] = [value].pack('C')
			end
		end

		def parsePayload(opCode, offset, payloadLen)
			case opCode
			when 1, 2
				on_packet @buffer_recv[offset, payloadLen]
			when 8
				@buffer_recv[offset, 2].unpack1('n')
				close
			end
		end
	end
end