class Counter
	def initialize interval
		@interval = interval
		@now = Time.now
	end

	def update
		now = Time.now
		return if now - @now < @interval
		@now = now
		yield
	end
end