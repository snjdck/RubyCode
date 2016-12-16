require_relative 'ioc'

module Model
	def regProxy proxyType
		proxy = proxyType.new
		proxy.instance_variable_set(:@application, @application)
		proxy.instance_variable_set(:@plugin, self)
		@injector.mapValue proxyType, proxy
	end
	def delProxy proxyType
		@injector.unmap proxyType
	end
	def hasProxy proxyType
		@injector.hasMapping proxyType
	end
end

module Proxy
	def notify name, data=nil
		@plugin.notify name, data
	end
	def notifyAll name, data=nil
		@application.notify name, data
	end
end

module Controller
	def regCmd name, handler
		list = cmdList(name)
		return if list.include? handler
		@injector.injectInto(handler)
		list.push(handler)
	end
	def delCmd name, handler
		list = cmdList(name)
		list.delete(handler)
	end
	def notify name, data=nil
		for handler in cmdList(name)
			handler.call data
		end
	end
	private def cmdList name
		@cmdDict ||= {}
		@cmdDict[name] ||= []
	end
end

class Application include Controller
	attr_reader :injector

	def initialize
		@injector = Injector.new
		@injector.mapValue Injector, @injector
		@injector.mapValue Application, self
		@pluginDict = {}
	end

	def regPlugin pluginType
		plugin = pluginType.new
		@injector.injectInto(plugin)
		@pluginDict[pluginType] = plugin
	end

	def regService interface, klass, moduleInjector=nil
		@injector.mapSingleton(interface, klass, realInjector: moduleInjector)
	end

	def startup
		unless @hasStartup
			onStartup
			@hasStartup = true
		end
	end

	def onUpdate
		@pluginDict.each_value { |plugin|  plugin.onUpdate }
	end
	private def onStartup
		@pluginDict.each_value { |plugin|  plugin.initAllModels }
		@pluginDict.each_value { |plugin|  plugin.initAllServices }
		@pluginDict.each_value { |plugin|  plugin.initAllControllers }
		@pluginDict.each_value { |plugin|  plugin.onStartup }
	end
end

class Plugin include Model, Controller
	Inject(:application, Application)
	Inject(:onInit)

	def initialize
		@injector = Injector.new
		@injector.mapValue Injector, @injector
		@injector.mapValue Plugin, self
	end

	private def onInit
		@injector.parent = @application.injector
	end

	def regService interface, klass, asLocal=false
		if asLocal
			@injector.mapSingleton interface, klass
		else
			@application.regService interface, klass, @injector
		end
	end

	def initAllModels; end
	def initAllServices; end
	def initAllControllers; end
	def onStartup; end
	def onUpdate; end
end