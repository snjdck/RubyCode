class Injector
	class InjectionTypeClass
		def initialize(klass, realInjector)
			@realInjector = realInjector
			@klass = klass
		end
		def call(injector, id, target)
			@realInjector.injectInto(new @klass)
		end
		private
		def new(type, args=nil)
			case type
			when Class then type.new  *args
			when Proc  then type.call *args
			when Array
				type, *args = type
				type = new type if Array === type
				new type, args
			else nil
			end
		end
	end

	class InjectionTypeSingleton < InjectionTypeClass
		def call(injector, id, target)
			return @value if @value
			@value = new @klass
			@realInjector.injectInto(@value)
		end
	end

	class InjectionTypeValue
		def initialize(value, needInject, realInjector)
			@realInjector = realInjector
			@value  = value
			@needInject = needInject
		end
		def call(injector, id, target)
			return @value unless @needInject
			@needInject = false
			@realInjector.injectInto(@value)
		end
	end
end