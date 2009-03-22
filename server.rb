require "socket"

server = TCPServer.open(8080)

QUEUES = {}

Thread.new do
  loop do
    Thread.start(server.accept) do |s|
      print(s, " is accepted\n")
      if %r|<policy-file-request/>| === s.gets("\0")
        $stderr.puts "sending policy file..."
        s.write("<cross-domain-policy><allow-access-from domain='*' to-ports='*'/></cross-domain-policy>\0")
        s.close
        return
      else
        QUEUES[Thread.current] = []

        loop do
          Thread.stop
          v = QUEUES[Thread.current].pop
          s.write("#{v}\n")
        end
      end
    end
  end
end

require 'wiimote'

class MyReceiver < Wii::Receiver
  def start(remote)
    super(remote)
    remote.setIRSensorEnabled(true)
    @status = Struct.new(:dpdX, :dpdY, :dpdRollX, :dpdRollY, :hold, :isEnabled, :isDataValid, :isBrowsing, :dpdValidity, :dpdScreenX, :dpdScreenY, :dpdDistance).new

    @status.isEnabled = 1
    @status.isDataValid = 1
    @status.isBrowsing = 1
    @status.dpdValidity = 1
  end

  def accelerationChanged_accX_accY_accZ(type, ax, ay, az)
    x = [az].pack("C").unpack("c").shift
    y = [ax].pack("C").unpack("c").shift

    l = Math.sqrt(x * x + y * y)
    @status.dpdRollX = x.quo(l)
    @status.dpdRollY = y.quo(l)
    send if rand < 0.1
  end

  def irPointMovedX_Y(px, py)
    @status.dpdX = px if (-1...1).include? px
    @status.dpdY = -py if (-1...1).include? py
    send if rand < 0.1
  end

  def buttonChanged_isPressed(btn_type, is_pressed)
    case btn_type 
    when 0
      btn = 2048
    when 1
      btn = 1024
    when 2
      btn = 512
    when 3
      btn = 256
    when 4
      btn = 4096
    when 5
      # home
    when 6
      btn = 16
    when 7
      btn = 8
    when 8
      btn = 4
    when 9
      btn = 1
    when 10
      btn = 2
    end
    
    return unless btn
    @status.hold ||= btn
    unless is_pressed
      @status.hold ^= btn
    end
    send if rand < 0.1
  end

  def send
    json = @status.members.map{|name| "#{name}:#{@status[name] ? @status[name] : 'undefined'}"}.join(',')
    json = "{#{json}}"
    QUEUES.each do |k, v|
      v << json
      k.run if k.alive?
    end
  end
end

Wii::Discovery.alloc.init(MyReceiver.new)
OSX::NSRunLoop.currentRunLoop.run
