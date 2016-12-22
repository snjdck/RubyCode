class Module
	def inject(name, type=nil, id=nil)
		info = Injector.getInjectInfo(self)
		unless type then info[name] = nil
		else info[:"@#{name}"] = [type, id]
		end
		name
	end
end