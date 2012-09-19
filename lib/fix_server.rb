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

class FIX::Engine::Server
	def initialize( )
	end
	def start()
	end
	def end()
	end

	private
	
end
