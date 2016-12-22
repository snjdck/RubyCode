module MVC
	module Model
		def regProxy(proxyType)
			proxy = proxyType.new
			proxy.instance_variable_set(:@application, @application)
			proxy.instance_variable_set(:@module, self)
			@injector.mapValue(proxyType, proxy)
		end

		def delProxy(proxyType)
			@injector.unmap(proxyType)
		end

		def hasProxy(proxyType)
			@injector.hasRule(proxyType)
		end
	end

	module Proxy
		def notify(name, data=nil)
			@module.notify(name, data)
		end

		def notifyAll(name, data=nil)
			@application.notify(name, data)
		end
	end
end