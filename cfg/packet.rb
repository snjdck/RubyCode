module PacketMsgID
	@dict = {}
	def self.add(name, id, svrId)
		raise if @dict.any? { |key, value| key == id || value[0] == name }
		@dict[id] = [name, ServerID.const_get(svrId)]
	end
	def self.findName(id)
		@dict[id][0]
	end
	def self.findSvrId(id)
		info = @dict[id]
		info[1] if info
	end
end

module PacketMsgID
	add :TEST, 1, :LOGIC
end