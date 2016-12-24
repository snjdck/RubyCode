$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'test/unit'
require 'ioc'

class TestInjector < Test::Unit::TestCase
	def setup
	end

	def teardown
	end

	def test_a
		injector = Injector.new
		assert_nil(injector.getInstance(A))
	end

	def test_b
		injector = Injector.new
		injector.mapValue(Injector, injector)
		injector.mapClass(A)
		injector.mapSingleton(B, proc{B.new})
		assert_equal(injector.getInstance(Injector), injector.getInstance(Injector))

		t = Test1.new
		injector.injectInto(t)
		assert_equal t.name, t.sex
		assert_not_equal t.a1, t.a2
		assert_equal t.b1, t.b2
	end

	def test_nest1
		injector = Injector.new
		injector.mapValue Nest, Nest.new, true
		nest = injector.getInstance(Nest)
		assert_same nest, nest.nest
	end

	def test_nest2
		injector = Injector.new
		injector.mapSingleton Nest
		nest = injector.getInstance(Nest)
		assert_same nest, nest.nest
	end

	def test_nest3
		assert_raise(SystemStackError){
			injector = Injector.new
			injector.mapClass Nest
			injector.getInstance(Nest)
		}
	end
end

class Nest
	attr inject :nest, Nest
end

class A; end
class B; end

class Test0
	attr inject :a1, A
	attr inject :a2, A
end

class Test1 < Test0
	attr inject(:name, Injector)
	attr inject(:sex, Injector)
	attr inject(:b1, B)
	attr inject(:b2, B)
end