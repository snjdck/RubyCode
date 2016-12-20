class Array
	def new
		type, *args = self
		type.new *args
	end
end

class Module
	def inject(name, type=nil, id=nil)
		info = Injector.getInjectInfo(self)
		unless type then info[name] = nil
		else info[:"@#{name}"] = [type, id]
		end
		name
	end
end

class InjectionTypeValue
	def initialize(value, needInject, realInjector)
		@realInjector = realInjector
		@value  = value
		@needInject = needInject
	end
	def getValue(injector, id, target)
		return @value unless @needInject
		@needInject = false
		@realInjector.injectInto(@value)
	end
end

class InjectionTypeSingleton
	def initialize(klass, realInjector)
		@realInjector = realInjector
		@klass = klass
	end
	def getValue(injector, id, target)
		return @value if @value
		@value = @klass.new
		@realInjector.injectInto(@value)
	end
end

class InjectionTypeClass
	def initialize(klass, realInjector)
		@realInjector = realInjector
		@klass = klass
	end
	def getValue(injector, id, target)
		@realInjector.injectInto(@klass.new)
	end
end

class Injector
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
		return rule.getValue(self, id, target) if rule
	end

	def injectInto(target)
		for cls in target.class.ancestors
			next unless info = @@InjectInfoDict[cls]
			for k, v in info
				next unless v
				target.instance_variable_set(k, getInstance(*v, target))
			end
			for k, v in info
				target.__send__(k) unless v
			end
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
end