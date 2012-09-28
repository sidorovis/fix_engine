if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'fix_engine/common/system_processor'
require 'test/unit'

Thread.abort_on_exception = true

class SystemProcessorTestHelper < FIX::Common::SystemProcessor
	def initialize
		super
	end
	def stop_with_sleep( interval = 0.05 )
		sleep( interval )
		stop
		self
	end
end

class SystemProcessorTest < Test::Unit::TestCase
	def test_initialize()
		assert_nothing_raised( Exception ) { FIX::Common::SystemProcessor.new }
		assert_nothing_raised( Exception ) { FIX::Common::SystemProcessor.new.process_ctrl_c.stop }
		assert_nothing_raised( Exception ) { SystemProcessorTestHelper.new.start.stop_with_sleep( 0.05 ) }
		assert_nothing_raised( Exception ) { SystemProcessorTestHelper.new.start.stop.wait }
	end
end
