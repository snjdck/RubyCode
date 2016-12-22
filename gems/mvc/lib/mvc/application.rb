module MVC
	class Application include Controller
		attr_reader :injector

		def initialize
			@moduleDict = {}
			@injector = Injector.new
			@injector.mapValue(Injector, @injector)
			@injector.mapValue(Application, self)
		end

		def regModule(moduleType)
			value = moduleType.new
			@injector.injectInto(value)
			@moduleDict[moduleType] = value
		end

		def regService(interface, klass, moduleInjector=nil)
			@injector.mapSingleton(interface, klass, realInjector: moduleInjector)
		end

		def startup
			return if @hasStartup
			@hasStartup = true
			onStartup
		end

		def onUpdate
			@moduleDict.each_value { |plugin|  plugin.onUpdate }
		end

		private
		
		def onStartup
			@moduleDict.each_value { |plugin|  plugin.initAllModels }
			@moduleDict.each_value { |plugin|  plugin.initAllServices }
			@moduleDict.each_value { |plugin|  plugin.initAllControllers }
			@moduleDict.each_value { |plugin|  plugin.onStartup }
		end
	end
end