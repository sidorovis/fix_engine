if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'rubygems'
require 'rev'
require 'fix_message'
require 'fix_session'
require 'fix_response'

class FIX::Engine
end

class FIX::Engine::Client < Rev::TCPSocket
	def initialize( )
	    @session = FIX::Session.new('FIX.4.2', 'etc/FIX42.xml')
		
	end
	def start()
	end
	def end()
	end

	private
	
end
