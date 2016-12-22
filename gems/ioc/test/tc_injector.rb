$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'test/unit'
require 'injector'

class TestInjector < Test::Unit::TestCase
	def setup
		@injector = Injector.new
	end

	def teardown
	end

	def test_a
		assert_nil(nil)
	end

	def test_b
		assert_equal("me", 'me')
	end
end