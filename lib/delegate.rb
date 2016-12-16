module DelegateMixin
	def self.included mod
		mod.extend ClassMethods
	end
	module ClassMethods
		def delegate method, attribute
			define_method method do |*args|
				target = instance_variable_get(attribute)
				target.__send__ method, *args
			end
		end
	end
end