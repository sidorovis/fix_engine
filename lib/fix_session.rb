if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'rubygems'
require 'libxml'

class FIX
end

class FIX::Session
  attr_reader :schema, :schema_fields
  attr_accessor :begin_string, :properties

  def initialize(begin_string, schema)
	schema = File.dirname(__FILE__) + "/" + schema if (!File.exists?( schema ))
    parser = LibXML::XML::Parser.file(schema)
    @schema = parser.parse

    @schema_fields = @schema.find('//fields')

    @begin_string = begin_string
    @properties = { 'MsgSeqNum' => 1 }
  end
end

