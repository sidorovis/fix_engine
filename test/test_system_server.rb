if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'system_server'
require 'test/unit'

class SystemServerTestHelper < FIX::Engine::SystemServer
	def initialize
		super(0.0)
	end
	def process_
		stop
	end
end

class SystemServerTestExceptionHelper < FIX::Engine::SystemServer
	attr_reader :count_call, :amount
	def initialize( amount = 5, sleep_intervale = 0.0 )
		@amount = amount
		@count_call = 0
		super( sleep_intervale )
	end
	def process_
		@count_call += 1
		stop if @count_call == @amount
		raise "Exception example" if @count_call == 1
	end
	def stop_with_sleep( interval = 0.05 )
		sleep( interval )
		stop
		self
	end
end

class SystemServerTest < Test::Unit::TestCase
	def test_initialize()
		assert_nothing_raised( Exception ) { FIX::Engine::SystemServer.new }
		assert_nothing_raised( Exception ) { FIX::Engine::SystemServer.new.process_ctrl_c.wait.stop }
		assert_nothing_raised( Exception ) { SystemServerTestHelper.new.wait }
		assert_nothing_raised( Exception ) { SystemServerTestHelper.new.start.wait.stop }
		assert_nothing_raised( Exception ) { SystemServerTestExceptionHelper.new.start.wait }
		assert_equal( SystemServerTestExceptionHelper.new(2).start.wait.count_call, 2 )
		assert_equal( SystemServerTestExceptionHelper.new(5).start.wait.count_call, 5 )
		count_call = SystemServerTestExceptionHelper.new(120, 0.01).start.stop_with_sleep( 0.05 ).count_call
		assert_equal( count_call >= 4 && count_call <= 6, true )				
	end
end
