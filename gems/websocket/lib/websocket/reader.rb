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
			@has_upgrade ? parse_data : parse_upgrade
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
			_begin, _end = 0, @buffer_recv.size
			until _end - _begin < 2
				byte1, byte2 = @buffer_recv.unpack('C2')

				hasMask = byte2 & 0x80 > 0
				bodyLen = byte2 & 0x7F
				
				headLen = calcHeadLen(bodyLen, hasMask)
				break if _end - _begin < headLen

				bodyLen = readBodyLen(bodyLen, _begin)
				break if _end - _begin < headLen + bodyLen

				_begin += headLen

				decodeBody(_begin, bodyLen) if hasMask

				opCode  = byte1 & 0xF
				payload = parseBody(opCode, _begin, bodyLen)

				_begin += bodyLen

				finFlag = byte1 & 0x80 > 0
				dispatch(finFlag, opCode, payload)
			end
			@buffer_recv[0, _begin] = '' if _begin > 0
		end

		def calcHeadLen(bodyLen, hasMask)
			(hasMask ? 4 : 0) + case
			when bodyLen <  126 then 2
			when bodyLen == 126 then 4
			else 10 end
		end

		def readBodyLen(bodyLen, offset)
			if bodyLen < 126 then bodyLen
			elsif bodyLen == 126
				@buffer_recv[offset+2, 2].unpack1('n')
			else
				@buffer_recv[offset+6, 4].unpack1('N')
			end
		end

		def decodeBody(offset, bodyLen)
			mask = @buffer_recv[offset - 4, 4].unpack('C4')
			bodyLen.times do |i|
				index = offset + i
				value = @buffer_recv[index].unpack1('C')
				value ^= mask[i % 4]
				@buffer_recv[index] = [value].pack('C')
			end
		end

		def parseBody(opCode, offset, bodyLen)
			case opCode
			when 0, 1, 2
				@buffer_recv[offset, bodyLen]
			when 8
				@buffer_recv[offset, 2].unpack1('n')
			end
		end

		def dispatch(finFlag, opCode, payload)
			if finFlag
				if opCode > 0
					if opCode & 0x8 > 0
						case opCode
						when 8 then close
						end
					else
						on_packet payload
					end
				else
					@fragments << payload
					on_packet @fragments.join('')
					@fragments = nil
				end
			elsif opCode > 0
				@fragments = [payload]
			else
				@fragments << payload
			end
		end
	end
end