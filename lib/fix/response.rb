if ( __FILE__ == $0 )
	$LOAD_PATH.unshift File.dirname(__FILE__)
end

require 'rubygems'
require 'libxml'

class FIX
end

class FIX::Response
  attr_reader :response

  def initialize(session, response)
    @session  = session
    @response = {}
    response.split("\01").each do |field|
      tag_to_set = nil
      val_to_set = nil
      tag, val = field.split('=', 2)
      if node_field = @session.schema_fields[0].find('field[@number=' + tag + ']')
        if node_field.length == 1
          tag_to_set = node_field[0].attributes['name']
          val_to_set = val
          #@response[node_field[0].attributes['name']] = val
        else
          tag_to_set = tag
          val_to_set = val
          #@response[tag] = val
        end
      else
        tag_to_set = tag
        val_to_set = val
        #@response[tag] = val
      end
      if @response.has_key?(tag_to_set)
        if @response[tag_to_set].is_a?(Array)
          @response[tag_to_set] << val_to_set
        else
          first_member = @response[tag_to_set]
          @response[tag_to_set] = [ first_member, val_to_set ]
        end
      else
        @response[tag_to_set] = val_to_set
      end
    end
  end

  def pretty_print(header = true)
    puts '*** Message ***' if header
    p @response
    puts '*** End Message ***'
    puts
  end
end
