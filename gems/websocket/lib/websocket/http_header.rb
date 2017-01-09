class HttpHeader
	attr_reader :method, :path, :version

	def initialize data
		data = data.split("\r\n")
		@method, @path, @version = data.shift.split(' ')
		@headers = {}
		data.each do |line|
			index = line.index(':')
			next unless index
			key = line[0, index].strip.downcase
			val = line[index+1, line.size].strip
			@headers[key] = val
		end
	end

	def [](key)
		@headers[key.downcase]
	end
end