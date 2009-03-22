require 'osx/cocoa'

OSX.require_framework "WiiRemote"

module Wii
  class Discovery < OSX::NSObject
    def init(receiver) 
      @discovery = OSX::WiiRemoteDiscovery.alloc.init
      @discovery.setDelegate(self)
      @discovery.start
      @receiver = receiver
    end

    def WiiRemoteDiscovered(remote)
      $stderr.puts "WiiRemoteDiscovered remote=#{remote.inspect}"
      @discovery.stop
      @receiver.start(remote)
      at_exit {remote.closeConnection}
    end

    def WiiRemoteDiscoveryError(code)
      $stderr.puts "WiiRemoteDiscoveryError code=%x" % code
      @discovery.start
    end

    def willStartWiimoteConnections
    end

    objc_method :willStartWiimoteConnections, %w{void}
    objc_method :WiiRemoteDiscovered        , %w{void id}
    objc_method :WiiRemoteDiscoveryError    , %w{void int}
  end

  class Receiver < OSX::NSObject
    def start(remote)
      @remote = remote
      @remote.setDelegate(self)
      @remote.setMotionSensorEnabled(true)
    end

    def irPointMovedX_Y(px, py)
    end

    def buttonChanged_isPressed(btn_type, is_pressed)
    end

    def accelerationChanged_accX_accY_accZ(type, ax, ay, az)
    end

    def wiiRemoteDisconnected(device)
    end

    def rawIRData(irData)
    end

    objc_method :irPointMovedX_Y, %w{void float float}
    objc_method :accelerationChanged_accX_accY_accZ, %w{void ushort uchar uchar uchar}
    objc_method :joyStickChanged_tiltX_tiltY, %w{void ushort uchar uchar}
    objc_method :buttonChanged_isPressed, %w{void ushort char}
    objc_method :wiiRemoteDisconnected, %w{void id}
    objc_method :rawIRData, "v@:^{_IRData=iii}"
  end
end
