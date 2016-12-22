#you should provide [close, on_recv, on_send] method for select.
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