if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'common/timer'
require 'test/unit'

class TimerTestHelper < FIX::Common::Timer
	def initialize
		super(0.0)
	end
	def process_
		stop
	end
end

class TimerTestExceptionHelper < FIX::Common::Timer
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

class TimerTest < Test::Unit::TestCase
	def test_initialize()
		assert_nothing_raised( Exception ) { FIX::Common::Timer.new }
		assert_nothing_raised( Exception ) { FIX::Common::Timer.new.process_ctrl_c.wait.stop }
		assert_nothing_raised( Exception ) { TimerTestHelper.new.wait }
		assert_nothing_raised( Exception ) { TimerTestHelper.new.start.wait.stop }
		assert_nothing_raised( Exception ) { TimerTestExceptionHelper.new.start.wait }
		assert_equal( TimerTestExceptionHelper.new(2).start.wait.count_call, 2 )
		assert_equal( TimerTestExceptionHelper.new(5).start.wait.count_call, 5 )
		count_call = TimerTestExceptionHelper.new(120, 0.01).start.stop_with_sleep( 0.05 ).count_call
		assert_equal( count_call >= 4 && count_call <= 6, true )				
	end
end
