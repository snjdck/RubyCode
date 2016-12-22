module SocketHandler
	def send_packet packet
		send_raw packet.to_s
	end

	def send_raw str
		return if closed? || str.empty?
		@buffer_send ||= ''
		unless @buffer_send.bytesize > 0
			$selector.add_send self
		end
		@buffer_send << str
	end

	def on_send
		bytesSend = send(@buffer_send, 0)
		if bytesSend < @buffer_send.bytesize
			@buffer_send[0, bytesSend] = ''
		else
			@buffer_send.clear
			$selector.del_send self
		end
	end

	def on_recv
		(@buffer_recv ||= '') << recv(4096)
		while packet = Packet.parse(@buffer_recv)
			case packet.type
			when Packet::TYPE_DEFAULT then on_packet  packet
			when Packet::TYPE_CONTROL then on_control packet
			end
		end
	end

	def close
		return if closed?
		$selector.remove self
		on_disconnect
		super
	end

	def puts obj
		$stdout.puts obj
	end

	def on_packet (packet); end
	def on_control(packet); end
	def on_connect; end
	def on_disconnect; end
end