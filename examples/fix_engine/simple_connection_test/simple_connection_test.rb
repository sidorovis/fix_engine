if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'fix_engine/common/tcp_server'
require 'fix_engine/common/tcp_client'
require 'test/unit'

Thread.abort_on_exception = true


class TCPServerObserverTestHelper < FIX::Common::TCPServerObserver
	attr_reader :actions
	def initialize
		@actions = []
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
		@actions << "on_client_connect(#{client})"
	end
	def on_client_disconnect( client )
		@actions << "on_client_disconnect(#{client})"
	end
	def on_client_receive_data( client, data )
		@actions << "on_client_receive_data(#{client},'#{data}')"
	end
end

class TCPClientObserverTestHelper < FIX::Common::TCPClientObserver
	attr_reader :actions
	def initialize
		@actions = []
	end
	def on_connected
		@actions << "on_connected"
	end
	def on_receive_data( data )
		@actions << "on_receive_data('#{data}')"
	end
	def on_disconnected
		@actions << "on_disconnected"
	end
end


class SimpleConnectionTest < Test::Unit::TestCase
	def test_connection()
		server_observer = TCPServerObserverTestHelper.new
		server = FIX::Common::TCPServer.new( 9123, server_observer )
		server.start
		client_observer = TCPClientObserverTestHelper.new
		client = FIX::Common::TCPClient.new( client_observer )
		client.start( "localhost", 9123 )
		client.send( "hello world" )
		sleep( 0.01 );
		server.send( server.connected_clients[0], "hello client" )
		sleep( 0.01 );
		client.stop
		server.stop
		assert_equal( 7, server_observer.actions.size() )
		assert_equal( 3, client_observer.actions.size() )
	end
end
