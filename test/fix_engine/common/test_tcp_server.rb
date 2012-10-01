if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'fix_engine/common/tcp_server'
require 'test/unit'

Thread.abort_on_exception = true

class TCPServerObserver < FIX::Common::TCPServerObserver
	attr_reader :actions, :clients
	attr_accessor :connection_signal, :disconnection_signal, :received_data, :data
	def initialize
		@actions = []
		@clients = Set.new
		@mutex = Mutex.new
		@waiter = ConditionVariable.new
		@received_data = 0
		@data = ""
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
			@data += data
			@waiter.signal
		end
		@actions << "on_receive_data(#{data})"
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
			assert_equal( "", client.recv( 128 ) )
			client.close
			assert_equal( server.stop, server )
			assert_equal( ['before_start', 'after_start', 'on_client_connect', 'on_client_disconnect', 'before_stop', 'after_stop'], observer.actions )
		end
	end
	def test_read_with_observer()
		assert_nothing_raised( Exception ) do
			observer = TCPServerObserver.new
			server = FIX::Common::TCPServer.new( 2000, observer )
			assert_equal( server.start, server )
			client = TCPSocket.new( "localhost", 2000 )
			observer.wait_connection
			assert_equal( server.connected_clients.size, 1 )
			assert_equal( server.connected_clients[0].class, TCPSocket )

			observer.received_data = 0
			th = Thread.new { client.write( "hello world, example message" ) }
			th.join
			observer.wait_receive_data( "hello world, example message".size ) 

			observer.received_data = 0
			th = Thread.new { client.write( "second message" ) }
			th.join
			observer.wait_receive_data( "second message".size ) 

			server.send( server.connected_clients[0], "answer example" )
			answer = client.readpartial( 128 )
			assert_equal( "answer example", answer )

			server.send( server.connected_clients[0], "Yo-Ho-Ho!" )
			answer = client.readpartial( 128 )
			assert_equal( "Yo-Ho-Ho!", answer )

			observer.received_data = 0
			th = Thread.new { client.write( "Yo-Ho-Ho!" ) }
			th.join
			observer.wait_receive_data( "Yo-Ho-Ho!".size ) 

			server.send( server.connected_clients[0], "Answer example" )
			answer = client.readpartial( 128 )
			assert_equal( "Answer example", answer )

			observer.received_data = 0
			th = Thread.new { client.write( "Hello developer, this is a test message. If you like it - call +37517102" ) }
			th.join
			observer.wait_receive_data( "Hello developer, this is a test message. If you like it - call +37517102".size ) 

			assert_equal( server.stop, server )
			assert_equal( [
				'before_start', 'after_start', 
				'on_client_connect', 
				'on_receive_data(hello world, example message)', 'on_receive_data(second message)', 'on_receive_data(Yo-Ho-Ho!)', 'on_receive_data(Hello developer, this is a test message. If you like it - call +37517102)', 
				'before_stop', 'on_client_disconnect', 'after_stop'], observer.actions )

		end
	end
	def test_multi_thread_reader
		assert_nothing_raised( Exception ) do
			observer = TCPServerObserver.new
			server = FIX::Common::TCPServer.new( 2000, observer )
			assert_equal( server.start, server )
			client = TCPSocket.new( "localhost", 2000 )
			observer.wait_connection
			assert_equal( server.connected_clients.size, 1 )
			assert_equal( server.connected_clients[0].class, TCPSocket )
			client_socket = server.connected_clients[0]

			listen_thread = Thread.new do
			    loop do
					observer.received_data = 0
					observer.data = ""
					observer.wait_receive_data( 5 )
					length = observer.data.to_i
					observer.received_data = 0
					observer.data = ""
					observer.wait_receive_data( length )
					break if length == 3 && observer.data == "END"
					server.send( client_socket, "prefix #{length} #{observer.data}" )
				end
			end
			writer_thread = Thread.new do
				100.times do |i|
					message = "hello world message #{i}"
					client.write( "%05d" % message.size )
					client.write( message )
					answer = client.readpartial( 128 )
					assert_equal( "prefix #{message.size} #{message}", answer )
				end
				message = "END"
				client.write( "%05d" % message.size )
				client.write( message )
			end
			writer_thread.join
			listen_thread.join
			client.close
			observer.wait_disconnection
			assert_equal( server.connected_clients.size, 0 )
			assert_equal( server.stop, server )
		end
	end
end
