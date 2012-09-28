if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'rubygems'
require 'thread'

class FIX
end

class FIX::Common
end

# FIX::Common::SystemProcessor class use Threads, please use Thread.abort_on_exception = true to debug/work with application
class FIX::Common::SystemProcessor
	attr_reader :working
	def initialize( sleep_time = 0.5 )
		@sleep_time = sleep_time
		@working_protector_ = Mutex.new
		@waiter_ = ConditionVariable.new
		@working = false
	end
	def start
		@working_protector_.synchronize { @working = true }
		self
	end
	def stop
		just_stop_
		wait
	end
	def wait
		@working_protector_.synchronize do 
			while @working
				@waiter_.wait( @working_protector_, @sleep_time )
			end
		end
		self
	end
	def process_ctrl_c
		trap("INT") { just_stop_ }
		self
	end
	private
	def just_stop_
		@working_protector_.synchronize do
			@working = false
			@waiter_.signal
		end				
	end
end
