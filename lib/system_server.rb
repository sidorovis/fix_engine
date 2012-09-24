if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'rubygems'
require 'thread'

class FIX
end

class FIX::Engine
end

class FIX::Engine::SystemServer
	attr_accessor :sleep_intervale
	attr_reader :working
	def initialize( sleep_intervale = 0.5 )
		@sleep_intervale = sleep_intervale
		@working_protector_ = Mutex.new
		@waiter_ = ConditionVariable.new
		@working = false
	end
	def start
		@thread = Thread.new do
			@working_protector_.lock
			@working = true
			while @working do
				@working_protector_.unlock
				st = Time.now
				safe_process_
				se = Time.now
				@working_protector_.lock
				break unless (@working)
				sleep_( se - st )
			end
			@working_protector_.unlock
		end
		self
	end
	def stop
		if Thread.current == @thread
			@working = false
		else
			just_stop_
			wait
		end
		self
	end
	def wait
		return self if @thread == nil
		@thread.join
		self
	end
	def process_ctrl_c
		@working_protector_.synchronize do
			@working_ = false
			trap("INT") { just_stop_ }
		end
		self
	end
	private
	def sleep_( process_execution_time )
		intervale = @sleep_intervale - process_execution_time
		intervale = 0.0 if intervale < 0.0
		@waiter_.wait( @working_protector_, intervale ) if intervale > 0.001
	end
	def just_stop_
		@working_protector_.synchronize do
			@working = false
			@waiter_.signal
		end				
	end
	def safe_process_
		begin
			process_
		rescue
		end
	end
	def process_
	end
end
