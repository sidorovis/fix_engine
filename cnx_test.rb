require 'pr-fix'
require 'rev'

## FILL THESE IN:
SenderCompId     = 'testuser1234'
SenderAuthID     = 'testusera1234'
LogonPassword    = 'testpass1234'
NewLogonPassword = 'testpass5678' # used if server forces a password change
ConnectHostIP    = '127.0.0.1'
ConnectPort      = '4433'

class ClientConnection < Rev::TCPSocket
  def on_connect
    @trading_session_open = false
    @subscribed = false
    @first_heartbeat_sent = false
    @sess = FIX::Session.new('FIX.4.2', 'etc/FIX42.xml')
    @sess.properties['SenderCompID']  = SenderCompID
    @sess.properties['TargetCompID']  = 'CNX'
    @sess.properties['HeartBtInt']    = 30
    @sess.properties['EncryptMethod'] = 0
    msg = FIX::Message.new(@sess, 'Logon')
    msg.add_field('554', LogonPassword)
    msg.add_field('141', 'Y')
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
      @first_heartbeat_sent = true unless @first_heartbeat_sent
      @sess.properties['MsgSeqNum'] += 1
      write FIX::Message.new(@sess, 'Heartbeat').to_s

    when '5'
      # logout
      close

    when 'h'
      # trading session status
      if @trading_session_open
        puts 'Got trading session status when session was open!!!'
      else
        if (resp.response['TradSesStatus'] == '2')
          @trading_sessin_open = true
          puts 'Trading session open'
          self.cmd_subscribe_data
        else
          puts 'Trading session not open'
          if resp.response['TradSesStatus'] == '1' && resp.response['Text'] == 'Password reset is required'
            # reset password plz
            @sess.properties['MsgSeqNum'] += 1
            msg = FIX::Message.new(@sess, 'BE')
            msg.add_field('923', 'bleeblah')
            msg.add_field('924', '3')
            msg.add_field('553', SenderAuthID)
            msg.add_field('554', LogonPassword)
            msg.add_field('925', NewLogonPassword)
            msg_s = msg.to_s
            puts "Sending message:"
            FIX::Response.new(@sess, msg_s).pretty_print(false)
            write msg_s
          end
        end
      end
    end
  end
 
  def on_resolve_failed
    print "DNS resolve failed"
  end
 
  def on_connect_failed
    print "connect failed, meaning our connection to their port was rejected"
  end

  def cmd_subscribe_data
    # market data subscription request
    if !@subscribed
      sleep 2
      @sess.properties['MsgSeqNum'] += 1
      msg = FIX::Message.new(@sess, 'V')
      msg.add_field('MDReqID', Time.now.to_i.to_s)
      msg.add_field('SubscriptionRequestType', '1')
      msg.add_field('MarketDepth', '0')
      msg.add_field('MDUpdateType', '1')
      msg.add_field('AggregatedBook', 'Y')
      msg.add_field('NoMDEntryTypes', '2')
      msg.add_field('MDEntryType', '0')
      msg.add_field('MDEntryType', '1')
      msg.add_field('NoRelatedSym', '1')
      msg.add_field('Symbol', 'USD/JPY')
      msg.add_field('7560', 'N')
      msg_s = msg.to_s
      puts "Sending message:"
      FIX::Response.new(@sess, msg_s).pretty_print(false)
      write msg_s
      @subscribed = true
    end
  end
end

event_loop = Rev::Loop.default
client = ClientConnection.connect(ConnectHost, ConnectPort)
client.attach(event_loop)
event_loop.run 
