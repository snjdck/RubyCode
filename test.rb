
require_relative "lib/ioc"

class A end
class B end

class Test0
	attr Inject(:a1, A)
	attr Inject(:a2, A)
end

class Test < Test0
	attr Inject(:name, Injector)
	attr Inject(:sex, Injector)
	attr Inject(:b1, B)
	attr Inject(:b2, B)
end


injector = Injector.new Injector.new
puts injector.getInstance(A) == nil
injector.mapValue(Injector, injector)
injector.mapClass(A)
injector.mapSingleton(B)
puts injector.parent
puts injector.getInstance(Injector) == injector.getInstance(Injector)
t = Test.new
injector.injectInto(t)
puts t.name == t.sex
puts "--------------"
puts t.a1 == t.a2
puts t.b1 == t.b2
puts Injector.name

a = def ttt() end
p a
gets