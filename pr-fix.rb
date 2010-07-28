require 'rubygems'
require 'libxml'

class FIX
end

class FIX::Message
  def initialize(session, msg_type, extra_fields = false)
    @session      = session
    @begin_string = session.begin_string
    @fields       = []
    @msg_def      = nil

    # process msg_type
    if @msg_def = @session.schema.find('//messages/message[@name="' + msg_type + '"]')
      if @msg_def.length == 1
        @msg_type = @msg_def[0].attributes['msgtype']
      else
        @msg_def = nil ## TODO: fix this ##
        @msg_type = msg_type
      end
    else
      @msg_type = msg_type
    end

    # add in any extra fields
    if extra_fields
      extra_fields.each_key do |key|
        self.add_field(key, extra_fields[key])
      end
    end
  end

  def to_s
    # required header fields
    @session.schema.find('//header/field[@required="Y"]').each do |el|
      if ![ 'BeginString', 'BodyLength', 'MsgType', 'SendingTime' ].include?(el.attributes['name'])
        if @session.properties.has_key?(el.attributes['name'])
          self.add_field(el.attributes['name'], @session.properties[el.attributes['name']])
        else
          raise "Field '#{el.attributes['name']}' required by message type #{@msg_type}, but could not locate data."
        end
      end
    end

    # sending time
    #self.add_field('SendingTime', Time.new.utc.strftime('%Y%m%d-%H:%M:%S.%3N')) # ruby 1.9 only
    t = Time.new.utc # the following is ruby 1.8-compatible:
    tf = t.to_f
    self.add_field('SendingTime', Time.new.utc.strftime('%Y%m%d-%H:%M:%S.') + ((tf - tf.floor) * 1000).round.to_s.ljust(3, '0'))

    # required message definition fields
    if @msg_def
      @msg_def[0].find('field[@required="Y"]').each do |el|
        if @session.properties.has_key?(el.attributes['name'])
          self.add_field(el.attributes['name'], @session.properties[el.attributes['name']])
        else
          raise "Field '#{el.attributes['name']}' required by message type #{@msg_type}, but could not locate data."
        end
      end
    end

    # return
    self.msg_to_string
  end

  def add_field(name, value)
    if name =~ /^\d+$/
      @fields << "#{name}=#{value}"
    else
      if @el_field = @session.schema_fields[0].find('field[@name="' + name + '"]')
        if @el_field.length == 1
          @fields << "#{@el_field[0].attributes['number']}=#{value}"
        else
          raise "No field '#{name}' in schema."
        end
      else
        raise "No field '#{name}' in schema."
      end
    end
  end

  protected

  def msg_to_string
    msg_body_str = msg_body
    msg_str = "8=#{@begin_string}" + "\01" + "9=#{msg_body_str.length}" + msg_body_str + "\01"
    msg_str + checksum_field(msg_str) + "\01"
  end

  def msg_body
    "\01" + "35=#{@msg_type}" + "\01" + @fields.join("\01")
  end

  def checksum_field(str)
    i = 0
    str.each_byte do |b|
      i += b# unless b == 1
    end
    checksum = (i % 256).to_s.rjust(3, '0')
    "10=#{checksum}"
  end
end

class FIX::Session
  attr_reader :schema, :schema_fields
  attr_accessor :begin_string, :properties

  def initialize(begin_string, schema)
    parser = LibXML::XML::Parser.file(schema)
    @schema = parser.parse

    @schema_fields = @schema.find('//fields')

    @begin_string = begin_string
    @properties = { 'MsgSeqNum' => 1 }
  end
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
