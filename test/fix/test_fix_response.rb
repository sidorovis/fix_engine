if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'fix/response'
require 'fix/session'
require 'test/unit'

class FixResponseTest < Test::Unit::TestCase
	def test_initialize()
		assert_raise( ArgumentError ) { FIX::Response.new }
		session = FIX::Session.new("FIX.4.2", "etc/FIX42.xml")
		assert_raise( ArgumentError ) { FIX::Response.new( session ) }
		assert_nothing_raised( ArgumentError ) { FIX::Response.new( session, "" ) }
		assert_nothing_raised( ArgumentError ) { FIX::Response.new( session, "" ).response }
		assert_equal( FIX::Response.new( session, "" ).response.size, 0 )
		assert_equal( FIX::Response.new( session, "8=76" ).response.size, 1 )
		assert_equal( FIX::Response.new( session, "8=76" ).response[ 'BeginString' ], "76" )
		assert_equal( FIX::Response.new( session, "8=76#{1.chr}56=hello" ).response[ 'TargetCompID' ], "hello" )
		assert_equal( FIX::Response.new( session, "8=76#{1.chr}156=hello" ).response[ 'SettlCurrFxRateCalc' ], "hello" )
		assert_equal( FIX::Response.new( session, "8=76#{1.chr}33=3#{1.chr}58=hello#{1.chr}58=world#{1.chr}58=eoln" ).response[ 'Text' ], ["hello", "world", "eoln"] )
		assert_equal( FIX::Response.new( session, "8=76#{1.chr}556646=3" ).response[ '556646' ], "3" )
		assert_equal( FIX::Response.new( session, "8=76#{1.chr}556646=3#{1.chr}556646=hello" ).response[ '556646' ], ["3", "hello"] )
	end
end
