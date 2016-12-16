require_relative 'packet'

class Selector
	def initialize()
		@recv_list = []
		@send_list = []
		@dead_list = {}
	end

	def add_recv sock
		@recv_list << sock
	end

	def add_send sock
		@send_list << sock
	end

	def del_send sock
		@send_list.delete(sock)
	end

	def remove sock
		@recv_list.delete(sock)
		@send_list.delete(sock)
	end

	def run interval=nil
		loop do
			update interval
			yield if block_given?
		end
	end

	private

	def update interval
		list = select(@recv_list, @send_list, nil, interval)
		return unless list
		foreach list[0] do |sock| sock.on_recv end
		foreach list[1] do |sock| sock.on_send end
		del_dead_socks
	end

	def foreach(list)
		for sock in list
			next if sock.closed? || @dead_list[sock]
			begin
				yield sock
			rescue Errno::ECONNRESET, Errno::ECONNABORTED
				@dead_list[sock] = true
			end
		end
	end

	def del_dead_socks
		@dead_list.each_key &:close
		@dead_list.clear
	end
end

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

$selector = Selector.new