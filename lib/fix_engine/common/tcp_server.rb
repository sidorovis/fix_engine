if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
	$LOAD_PATH.unshift File.expand_path("../..",File.dirname(__FILE__))
end

require 'socket'
require 'set'

class FIX
end

class FIX::Common
end


class FIX::Common::TCPServerObserver
	def initialize
	end
	def before_start
	end 
	def after_start
	end
	def before_stop
	end 
	def after_stop
	end
	def on_client_connect( client )
	end
	def on_client_disconnect( client )
	end
	def on_client_receive_data( client, data )
	end
end

# FIX::Common::TCPServer class use Threads, please use Thread.abort_on_exception = true to debug/work with application
class FIX::Common::TCPServer
	attr_reader :port
	def initialize( port, observer = nil, buffer_size = 10240 )
		@port = port
		@observer_ = observer
		@buffer_size = buffer_size
		@accept_thread_ = nil

		@client_sockets_protector_ = Mutex.new
		@client_sockets_ = Hash.new

		@closing_sockets_protector_ = Mutex.new
		@closing_sockets_ = Set.new
	end
	def start
		@observer_.before_start if @observer_
		@server_ = TCPServer.new @port
		@working = true
		run_accept_thread_	
		@observer_.after_start if @observer_
		self
	end
	def stop
		@observer_.before_stop if @observer_
		@working = false
		@server_.close
		@accept_thread_.join
		@client_sockets_protector_.synchronize do
			@client_sockets_.each do |socket, thread| 
				disconnect_socket_protector_synchronized_( socket )
			end
		end
		@observer_.after_stop if @observer_
		self
	end
	def disconnect( client )
		return false if !add_client_socket_to_closing_set_( client ) 
		client.close
		@client_sockets_protector_.synchronize do
			unless @client_sockets_.include? client
				del_client_socket_to_closing_set_( client )
				return false 
			end
			read_thread = @client_sockets_.delete client
			read_thread.join
		end
		@observer_.on_client_disconnect( client ) if @observer_
		del_client_socket_to_closing_set_( client )
		return true
	end
	private
	def add_client_socket_to_closing_set_( client )
		@closing_sockets_protector_.synchronize do
			return false if @closing_sockets_.include? client
			@closing_sockets_ << client
		end
		return true
	end
	def del_client_socket_to_closing_set_( client )
		@closing_sockets_protector_.synchronize do
			@closing_sockets_.delete client
		end
	end
	def disconnect_no_wait_read_thread_( client )
		return false if !add_client_socket_to_closing_set_( client ) 
		client.close
		@client_sockets_protector_.synchronize do
			unless @client_sockets_.include? client
				del_client_socket_to_closing_set_( client )
				return false 
			end
			@client_sockets_.delete client
		end
		@observer_.on_client_disconnect( client ) if @observer_
		del_client_socket_to_closing_set_( client )
		return true
	end
	def disconnect_socket_protector_synchronized_( client )
		return false if !add_client_socket_to_closing_set_( client ) 
		client.close

		unless @client_sockets_.include? client
			del_client_socket_to_closing_set_( client )
			return false 
		end
		read_thread = @client_sockets_.delete client
		read_thread.join

		@observer_.on_client_disconnect( client ) if @observer_
		del_client_socket_to_closing_set_( client )
		return true
	end
	public
	def connected_clients
		result = []
		@client_sockets_protector_.synchronize { @client_sockets_.each { |socket,  thread| result << socket } }
		result
	end
	def send( client, message )
		sent_amount = 0
		begin
			sent_amount = client.send( message, 0 )
		rescue Errno::ECONNRESET
			disconnect( client )
		end
		sent_amount
	end
	private
	def run_accept_thread_
		@accept_thread_ = Thread.new do
			while @working
				begin
					client = @server_.accept
				rescue Errno::ENOTSOCK, IOError, Errno::EBADF
					break
				end
				run_client_processing_thread_ client
			end
		end
	end
	def run_client_processing_thread_( client )
		client_processing_thread = Thread.new do
			while @working do
				begin
					received = client.readpartial( @buffer_size )
				rescue IOError, Errno::EBADF, Errno::ECONNRESET
					break
				end
				break if !received || received.empty? 
				@observer_.on_client_receive_data( client, received ) if @observer_
			end
			disconnect_no_wait_read_thread_( client )
		end
		@client_sockets_protector_.synchronize { @client_sockets_[ client ] = client_processing_thread }
		@observer_.on_client_connect( client ) if @observer_
	end
end

