module MVC
	module Controller
		def regCmd(name, handler)
			list = cmdList(name)
			return if list.include? handler
			@injector.injectInto(handler)
			list << handler
		end

		def delCmd(name, handler)
			list = cmdList(name)
			list.delete(handler)
		end

		def notify(name, data=nil)
			for handler in cmdList(name)
				handler.call(data)
			end
		end

		private

		def cmdList(name)
			@cmdDict ||= {}
			@cmdDict[name] ||= []
		end
	end
end