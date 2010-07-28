require 'pr-fix'
require 'rev'

class ClientConnection < Rev::TCPSocket
  def on_connect
    @sess = FIX::Session.new('FIX.4.2', 'etc/FIX42.xml')
    @sess.properties['SenderCompID']  = 'BANZAI'
    @sess.properties['TargetCompID']  = 'EXEC'
    @sess.properties['HeartBtInt']    = 30
    @sess.properties['EncryptMethod'] = 0
    msg = FIX::Message.new(@sess, 'Logon')
    msg_s = msg.to_s
    puts "Sending message:"
    FIX::Response.new(@sess, msg_s).pretty_print(false)
    write msg_s
  end
 
  def on_read(data)
    puts "Received message:"
    resp = FIX::Response.new(@sess, data)
    resp.pretty_print(false)

    case resp.response['MsgType']
    when '0'
      # heartbeat
      @sess.properties['MsgSeqNum'] += 1
      write FIX::Message.new(@sess, 'Heartbeat').to_s
    when '5'
      # logout
      close
    when 'h'
      # trading session status
      puts (resp.response['TradSesStatus'] == '2') ? 'Trading session open' : 'Trading session not open'
    end
  end
 
  def on_resolve_failed
    print "DNS resolve failed"
  end
 
  def on_connect_failed
    print "connect failed, meaning our connection to their port was rejected"
  end
end
 
event_loop = Rev::Loop.default
client = ClientConnection.connect('127.0.0.1', 9878)
client.attach(event_loop)
event_loop.run 
