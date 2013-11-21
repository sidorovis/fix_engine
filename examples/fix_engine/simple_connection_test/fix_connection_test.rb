if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'fix_engine/common/tcp_server'
require 'fix_engine/common/tcp_client'
require 'fix_engine/fix/session'
require 'fix_engine/fix/message'
require 'fix_engine/fix/response'
require 'test/unit'

Thread.abort_on_exception = true

class FixServerObserverTestHelper < FIX::Common::TCPServerObserver
	attr_reader :actions
	def initialize
		@actions = []
		@clients = {}
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
		@clients[ client ] = "new_client"
	end
	def on_client_disconnect( client )
		@actions << "on_client_disconnect(#{client})"
		@clients.erase( client )
	end
	def on_client_receive_data( client, data )
		@actions << "on_client_receive_data(#{client},'#{data}')"
		if ( !@clients.has_key?( client ) )
			@actions << "unknown client send message( #{client} )"
			client.shutdown
			client.close
			client = nil
			return
		end
		if ( @clients[ client ].class == String ) # processing not_logon session
			puts data[2,7]
			if ( data[2,7] != "FIX.4.2")
				@actions << "bad session protocol( #{client} )"
				client.shutdown
				client.close
				client = nil
			end
			return
		end
	end
end

class FixClientObserverTestHelper < FIX::Common::TCPClientObserver
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
	def test_fix_connection()
		server_observer = FixServerObserverTestHelper.new
		server = FIX::Common::TCPServer.new( 9123, server_observer )
		server.start

		client_observer = FixClientObserverTestHelper.new
		client = FIX::Common::TCPClient.new( client_observer )
		client.start( "localhost", 9123 )

		client_session = FIX::Session.new("FIX.4.2", "etc/FIX42.xml")
		client_session.properties[ 'SenderCompID' ] = "TestSender"
		client_session.properties[ 'TargetCompID' ] = "TestTarget"
		client_session.properties[ 'EncryptMethod' ] = "0"
		client_session.properties[ 'HeartBtInt' ] = "60"

		client_logon = FIX::Message.new( client_session, "Logon" )
		client.send( client_logon.to_s )
		sleep(0.5)

	end
end
