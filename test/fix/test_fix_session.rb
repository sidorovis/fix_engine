if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'fix/session'
require 'test/unit'

class FixSessionTest < Test::Unit::TestCase
	def test_initialize()
		assert_raise( ArgumentError ) { FIX::Session.new }
		assert_nothing_raised( ArgumentError ) { FIX::Session.new("FIX.4.2", "etc/FIX42.xml") }
		session = FIX::Session.new("FIX.4.2", "etc/FIX42.xml")
		assert_equal( session.properties.size, 1 )
		assert_equal( session.properties['MsgSeqNum'], 1 )
		assert_equal( session.begin_string, "FIX.4.2" )
		assert_equal( session.schema_fields.class, LibXML::XML::XPath::Object )
	end
end
