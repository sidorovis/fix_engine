if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
	$LOAD_PATH.unshift File.expand_path("../..",File.dirname(__FILE__))
end

require 'socket'

class FIX
end

class FIX::Common
end


class FIX::Common::TCPClientObserver
	def initialize
	end
	def on_connected
	end
	def on_receive_data( data )
	end
	def on_disconnected
	end
end

# FIX::Common::TCPClient class use Threads, please use Thread.abort_on_exception = true to debug/work with application
class FIX::Common::TCPClient
	attr_reader :buffer_size
	def initialize( observer = nil, buffer_size = 10240 )
		@observer_ = observer
		@buffer_size = buffer_size
		@working_protector_ = Mutex.new
		@working_ = false
	end
	def start( ip_address, port )
		@socket_ = TCPSocket.new( ip_address, port )
		run_read_thread_
		@working_ = true
		self
	end
	def stop
		disconnect
	end
	def send( message )
		sent_amount = 0
		@working_protector_.synchronize do
			return sent_amount unless @working_
		end
		begin
			sent_amount = @socket_.send( message, 0 )
		rescue Errno::ECONNRESET
			disconnect
		end
		sent_amount		
	end
	def disconnect
		@working_protector_.synchronize do
			return self unless @working_
			@working_ = false
			@socket_.shutdown
			@socket_.close
			@working_protector_.unlock
			@read_thread_.join if @read_thread_
			@working_protector_.lock
			@observer_.on_disconnected if @observer_
		end
		self
	end
	private
	def disconnect_no_wait_read_thread_
		@working_protector_.synchronize do
			return unless @working_
			@working_ = false
			@observer_.on_disconnected if @observer_
		end
	end
	def run_read_thread_
		@read_thread_ = Thread.new do
			while @working_ do
				begin
					received = @socket_.readpartial( @buffer_size )
				rescue IOError, Errno::EBADF, Errno::ECONNRESET
					break
				end
				break if !received || received.empty? 
				@observer_.on_receive_data( received ) if @observer_
			end
			disconnect_no_wait_read_thread_ if @working_
		end
		@observer_.on_connected if @observer_
	end
end
