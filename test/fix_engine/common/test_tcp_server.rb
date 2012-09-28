if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'fix_engine/common/tcp_server'
require 'test/unit'

Thread.abort_on_exception = true

class TCPServerObserver < FIX::Common::TCPServerObserver
	attr_reader :actions, :clients
	attr_accessor :connection_signal, :disconnection_signal
	def initialize
		@actions = []
		@clients = Set.new
		@mutex = Mutex.new
		@waiter = ConditionVariable.new
		@received_data = 0
		@connection_signal = false
		@disconnection_signal = false
	end
	def wait_connection
		return if connection_signal
		@mutex.synchronize { @waiter.wait( @mutex ) }
	end
	def wait_disconnection
		return if disconnection_signal
		@mutex.synchronize { @waiter.wait( @mutex ) }
	end
	def wait_receive_data( count )
		@mutex.synchronize do
			while count > @received_data
				@waiter.wait( @mutex )
			end
		end
	end
	def disconnect( server )
		@actions << "disconnect"
		server.disconnect( @client )
	end
	def before_start
		@actions << "before_start"
	end 
	def after_start
		@actions << "after_start"
	end
	def before_stop
		@actions << "before_stop"
	end 
	def after_stop
		@actions << "after_stop"
	end
	def on_client_connect( client )
		@actions << "on_client_connect"
		@clients << client
		@connection_signal = true
		@mutex.synchronize { @waiter.signal }
	end
	def on_client_disconnect( client )
		@actions << "on_client_disconnect"
		@clients.delete client
		@disconnection_signal = true
		@mutex.synchronize { @waiter.signal }
	end
	def on_client_receive_data( client, data )
		@mutex.synchronize do
			@received_data += data.size
			@waiter.signal
		end
		@actions << "on_client_receive_data"
	end	
end


class FixAcceptorTest < Test::Unit::TestCase
	def test_initialize()
		assert_raise( ArgumentError ) { FIX::Common::TCPServer.new }
		assert_nothing_raised( ArgumentError ) { FIX::Common::TCPServer.new( 2000 ) }
		assert_nothing_raised( ArgumentError ) { FIX::Common::TCPServer.new( 2000, nil ) }
		assert_nothing_raised( ArgumentError ) { FIX::Common::TCPServer.new( 2000, nil, 1024 ) }
	end
	def test_start()
		assert_nothing_raised( Exception ) do
			server = FIX::Common::TCPServer.new( 2000 )
			assert_equal( server.start, server )
			server2 = FIX::Common::TCPServer.new( 2000 )
			server.start
			assert_raise( Errno::EADDRINUSE ) { server2.start }
			server.stop
		end
	end
	def test_stop()
		assert_nothing_raised( Exception ) do
			server = FIX::Common::TCPServer.new( 2000 )
			assert_equal( server.start, server )
			assert_equal( server.stop, server )
		end
	end
	def test_client_connection()
		assert_nothing_raised( Exception ) do
			assert_raise( Errno::ECONNREFUSED ) { client = TCPSocket.new( "localhost", 2000 ) }
			server = FIX::Common::TCPServer.new( 2000 )
			assert_equal( server.start, server )
			client = nil
			client = TCPSocket.new( "localhost", 2000 )
			assert_equal( client.class, TCPSocket )
			assert_equal( server.stop, server )
		end
	end
	def test_connected_clients()
		assert_nothing_raised( Exception ) do
			observer = TCPServerObserver.new
			server = FIX::Common::TCPServer.new( 2000, observer )
			assert_equal( server.start, server )
			client = nil
			assert_equal( server.connected_clients, [] )
			client = TCPSocket.new( "localhost", 2000 )
			assert_equal( client.class, TCPSocket )
			observer.wait_connection
			assert_equal( server.connected_clients.size, 1 )
			assert_equal( server.connected_clients[0].class, TCPSocket )
			client.close
			observer.wait_disconnection
			assert_equal( server.connected_clients.size, 0 )
			assert_equal( server.stop, server )
			assert_equal( ['before_start', 'after_start', 'on_client_connect', 'on_client_disconnect', 'before_stop', 'after_stop'], observer.actions )
		end
	end
	def test_connected_client_on_server_close()
		assert_nothing_raised( Exception ) do
			observer = TCPServerObserver.new
			server = FIX::Common::TCPServer.new( 2000, observer )
			assert_equal( server.start, server )
			client = TCPSocket.new( "localhost", 2000 )
			observer.wait_connection
			assert_equal( server.connected_clients.size, 1 )
			assert_equal( server.connected_clients[0].class, TCPSocket )
			observer.clients.each { |client| server.disconnect( client ) }
			observer.wait_disconnection
			assert_raise( Errno::ECONNRESET ) { client.read( 1 ) }
			assert_equal( server.stop, server )
		end
	end
end

=begin

		assert_nothing_raised( Exception ) do
			observer = TCPServerObserver.new
			server = FIX::Common::TCPServer.new( "test_tcp_server", 2000, observer ).start
#			assert_equal( server.connected_clients.size,  0)
			client = TCPSocket.new( "localhost", 2000 )
			observer.wait_connection
#			assert_equal( server.connected_clients.size, 1 )
			client.send("FIXMESSAGENOTDEFINED#{1.chr}MVUHAHA#{1.chr}1", 0 )
			client.send("FIXMESSAGENOTDEFINED#{1.chr}MVUHAHA#{1.chr}2", 0 )
			observer.wait_receive_data( "FIXMESSAGENOTDEFINED#{1.chr}MVUHAHA#{1.chr}1".size + "FIXMESSAGENOTDEFINED#{1.chr}MVUHAHA#{1.chr}2".size )
			observer.disconnect( server )
#			assert_equal( server.connected_clients.size, 0 )
			client.send("FIXMESSAGENOTDEFINED#{1.chr}MVUHAHA#{1.chr}3", 0 )
			client.close
			server.stop
#			assert_equal( ["before_start", "after_start", "on_client_connect", "on_client_receive_data", "disconnect", "before_stop", "after_stop" ], observer.actions )
#		end
#	end
#end
=end
