class Module
	def inject(name, type=nil, id=nil)
		info = Injector.getInjectInfo(self)
		unless type then info[name] = nil
		else info[:"@#{name}"] = [type, id]
		end
		name
	end
end

class Injector
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

	@@InjectInfoDict = {}

	def self.getInjectInfo(cls)
		@@InjectInfoDict[cls] ||= {}
	end

	attr_accessor :parent

	def initialize(parent=nil)
		@parent = parent
		@ruleDict = {}
	end

	def mapMetaRule(type, rule)
		@ruleDict[calcMetaKey(type)] = rule
	end

	def mapRule(type, rule, id=nil)
		@ruleDict[calcKey(type, id)] = rule
	end

	def unmap(type, id=nil)
		@ruleDict.delete calcKey(type, id)
	end

	def mapValue(type, value, needInject=false, id:nil, realInjector:nil)
		rule = InjectionTypeValue.new(value, needInject, realInjector || self)
		mapRule(type, rule, id)
	end

	def mapClass(type, value=nil, id:nil, realInjector:nil)
		rule = InjectionTypeClass.new(value || type, realInjector || self)
		mapRule(type, rule, id)
	end

	def mapSingleton(type, value=nil, id:nil, realInjector:nil)
		rule = InjectionTypeSingleton.new(value || type, realInjector || self)
		mapRule(type, rule, id)
	end

	def getInstance(type, id=nil, target=nil)
		rule = getRule(calcKey(type, id)) || getRule(calcMetaKey(type))
		rule.call(self, id, target) if rule
	end

	def injectInto(target)
		doInject(target) do |target, k, v|
			target.instance_variable_set(k, getInstance(*v, target)) if v
		end
		doInject(target) do |target, k, v|
			target.__send__(k) unless v
		end
		target
	end

	def hasRule(type, id=nil, inherit=true)
		getRule(calcKey(type, id), inherit) != nil
	end

	def hasMetaRule(type, inherit=true)
		getRule(calcMetaKey(type), inherit) != nil
	end

	protected

	def getRule(key, inherit=true)
		return @ruleDict[key] unless inherit
		injector = self
		begin
			rule = injector.getRule(key, false)
			return rule if rule
			injector = injector.parent
		end while injector
	end

	private

	def calcKey(type, id)
		return type.name if id.nil? || id.empty?
		return "#{type}@#{id}"
	end

	def calcMetaKey(type)
		return "#{type}@"
	end

	def doInject(target)
		for cls in target.class.ancestors
			next unless info = @@InjectInfoDict[cls]
			info.each { |k, v| yield target, k, v }
		end
	end
end