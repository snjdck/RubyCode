class Array
	def new
		cls, *args = self
		cls.new *args
	end
end

class Module
	def inject(name, type=nil)
		info = Injector.getInjectInfo(self)
		if type
			info[:"@#{name}"] = type
		else
			info[name] = nil
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
	def getValue(injector, id)
		if @needInject
			@realInjector.injectInto(@value)
			@needInject = false
		end
		@value
	end
end

class InjectionTypeClass
	def initialize(cls, realInjector)
		@realInjector = realInjector
		@cls = cls
	end
	def getValue(injector, id)
		@realInjector.injectInto(@cls.new)
	end
end

class InjectionTypeSingleton < InjectionTypeClass
	def getValue(injector, id)
		@val ||= super
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

	def mapValue(key, value, needInject=false, id:nil, realInjector:nil)
		rule = InjectionTypeValue.new(value, needInject, realInjector || self)
		mapRule(key, rule, id)
	end

	def mapClass(key, value=nil, id:nil, realInjector:nil)
		rule = InjectionTypeClass.new(value || key, realInjector || self)
		mapRule(key, rule, id)
	end

	def mapSingleton(key, value=nil, id:nil, realInjector:nil)
		rule = InjectionTypeSingleton.new(value || key, realInjector || self)
		mapRule(key, rule, id)
	end

	def getInstance(type, id=nil)
		rule = getRule(calcKey(type, id), true)
		return rule.getValue(self, id) if rule
		rule = getRule(calcMetaKey(type), true)
		return rule.getValue(self, id) if rule
	end

	def injectInto(target)
		for cls in target.class.ancestors 
			next unless info = @@InjectInfoDict[cls]
			for k, v in info
				next unless v
				target.instance_variable_set(k, getInstance(v))
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

	def getRule(key, inherit=false)
		return @ruleDict[key] unless inherit
		injector = self
		begin
			rule = injector.getRule(key)
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