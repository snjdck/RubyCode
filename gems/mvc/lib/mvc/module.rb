module MVC
	class Module include Model, Controller
		inject :application, Application

		def initialize
			@injector = Injector.new
			@injector.mapValue(Injector, @injector)
			@injector.mapValue(Module, self)
		end

		def regService(interface, klass, asLocal=false)
			if asLocal then @injector.mapSingleton(interface, klass)
			else @application.regService(interface, klass, @injector)
			end
		end

		def initAllModels; end
		def initAllServices; end
		def initAllViews; end
		def initAllControllers; end
		def onStartup; end
		def onUpdate; end

		private

		inject def onInit
			@injector.parent = @application.injector
		end
	end
end