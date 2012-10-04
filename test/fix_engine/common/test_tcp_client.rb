if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'fix_engine/common/tcp_client'
require 'test/unit'

Thread.abort_on_exception = true

class TCPClientObserver < FIX::Common::TCPClientObserver
	attr_reader :actions
	attr_accessor :connection_signal, :disconnection_signal, :received_data, :data
	def initialize
		@actions = []
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
		result = ""
		@mutex.synchronize do
			while count > @received_data
				@waiter.wait( @mutex )
			end
			result = @data[0..count-1]
			@data = @data[count..@data.length]
			@received_data -= count
		end
		return result
	end
	def on_connected
		@actions << "on_connected"
		@connection_signal = true
		@mutex.synchronize { @waiter.signal }
	end
	def on_receive_data( data )
		@actions << "on_receive_data(#{data})"
		@mutex.synchronize do
			@received_data += data.size
			@data += data
			@waiter.signal
		end
	end
	def on_disconnected
		@actions << "on_disconnected"
		@disconnection_signal = true
		@mutex.synchronize { @waiter.signal }
	end


end

class TCPClientTest < Test::Unit::TestCase
	def test_initialize()
		assert_nothing_raised( ArgumentError ) { FIX::Common::TCPClient.new }
		assert_nothing_raised( ArgumentError ) { FIX::Common::TCPClient.new( TCPClientObserver.new ) }
		assert_nothing_raised( ArgumentError ) { FIX::Common::TCPClient.new( TCPClientObserver.new, 1450 ) }
	end
	def test_start
		assert_raise( ArgumentError ) { FIX::Common::TCPClient.new().start() }
		assert_raise( ArgumentError ) { FIX::Common::TCPClient.new().start( "ip address" ) }
		assert_raise( SocketError ) { FIX::Common::TCPClient.new().start( "non", "adequate" ) }
		assert_raise( Errno::ECONNREFUSED ) { FIX::Common::TCPClient.new().start( "localhost", 2000 ) }
		thread = Thread.new do
			server = TCPServer.new( 2000 )
			connection = server.accept
			connection.close
			server.close
		end
		assert_nothing_raised( Errno::ECONNREFUSED ) { FIX::Common::TCPClient.new().start( "localhost", 2000 ) }
		thread.join
	end
	def test_stop
		thread = Thread.new do
			server = TCPServer.new( 2000 )
			connection = server.accept
			assert_raise( EOFError ) { result = connection.readpartial( 128 ) }
			server.close
		end
		observer = TCPClientObserver.new
		client = FIX::Common::TCPClient.new( observer ).start( "localhost", 2000 )
		client.stop
		thread.join
		assert_equal( [ "on_connected", "on_disconnected" ], observer.actions )

		thread = Thread.new do
			server = TCPServer.new( 2000 )
			connection = server.accept
			connection.close
			server.close
		end
		observer = TCPClientObserver.new
		client = FIX::Common::TCPClient.new( observer ).start( "localhost", 2000 )
		thread.join
		client.stop
		assert_equal( [ "on_connected", "on_disconnected" ], observer.actions )
	end
	def test_receive_data
		thread = Thread.new do
			server = TCPServer.new( 2000 )
			connection = server.accept
			connection.write( "00045" )
			connection.write( "piratiki" )
			sleep(0.01)
			connection.write( "-muratiki" )
			server.close
		end
		observer = TCPClientObserver.new
		client = FIX::Common::TCPClient.new( observer ).start( "localhost", 2000 )
		data = observer.wait_receive_data( 5 )
		assert_equal( "00045", data )
		data = observer.wait_receive_data( "piratiki-muratiki".size )
		assert_equal( "piratiki-muratiki", data )
		thread.join
		client.stop
		assert_equal( [ "on_connected", "on_receive_data(00045)", "on_receive_data(piratiki)", "on_receive_data(-muratiki)", "on_disconnected" ], observer.actions )
	end
	def test_send
		thread = Thread.new do
			server = TCPServer.new( 2000 )
			connection = server.accept
			connection.close
			server.close
		end
		observer = TCPClientObserver.new
		client = FIX::Common::TCPClient.new( observer ).start( "localhost", 2000 )
		sent = client.send( "hello world testing" )
		assert_equal( "hello world testing".size, sent )
		observer.wait_disconnection
		sent = client.send( "should fail" )
		assert_equal( 0, sent )
		thread.join
		client.stop
		assert_equal( [ "on_connected", "on_disconnected" ], observer.actions )
	end
	def test_multithread_send_receive
		server_thread = Thread.new do
			server = TCPServer.new( 2000 )
			connection = server.accept
			server.close

			100.times do |i|
				message = "message for testing #{i}"
				connection.send( "%05d" % message.size, 0 )
				connection.send( message, 0 )
				answer = connection.readpartial( 128 )
				assert_equal( "answer #{message} message",  answer)
			end
			connection.send( "%05d" % 3, 0 )
			connection.send( "END", 0 )
			answer = connection.readpartial( 128 )
			assert_equal( "ANSWER END",  answer)
			connection.close
		end
		client_thread = Thread.new do
			observer = TCPClientObserver.new
			client = FIX::Common::TCPClient.new( observer ).start( "localhost", 2000 )

			loop do
				length = observer.wait_receive_data( 5 ).to_i
				message = observer.wait_receive_data( length )
				break if (message == "END")
				assert_match( /message for testing \d+/, message )
				client.send( "answer #{message} message" )
			end
			client.send( "ANSWER END" )
			observer.wait_disconnection
			client.stop
		end
		server_thread.join
		client_thread.join
	end
end
