if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'fix_session'
require 'test/unit'


class FixSessionTest < Test::Unit::TestCase
	def test_initialize()
		assert_raise( ArgumentError ) { FIX::Session.new }
		assert_nothing_raised( ArgumentError ) { FIX::Session.new("FIX.4.2", "etc/FIX42.xml") }
	end
end