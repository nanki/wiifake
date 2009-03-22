/*
 * copyright 2009 dotswitch inc.
 * NANKI Haruo <nanki@dotswitch.net>.
 */

package {
  import flash.external.ExternalInterface;
  import flash.system.Security;
  import flash.text.TextField;
  import flash.utils.Timer;
  import flash.display.*;
  import flash.events.*;

  [SWF(width="640", height="480")]
  public class WiiProxy extends Sprite {
    public function WiiProxy() {
      setup();
    }

    private var socket:WiiSocket;
    private var t:TextField = new TextField();

    private function setup():void {
      addChild(t);

      socket = new WiiSocket();
      socket.connect('localhost', 8080);

      var timer:Timer = new Timer(5000);
      timer.addEventListener('timer', function():void {
        if (!socket.connected) {
          socket.connect('localhost', 8080);
        }
      });
      socket.addEventListener(Event.CLOSE  , function():void {timer.start()});
      socket.addEventListener(Event.CONNECT, function():void {timer.stop() });

      Security.allowDomain('*');
      ExternalInterface.addCallback('updateWiiStatus', function():String {return socket.wiiStatus});
    }
  }
}

import flash.net.Socket;
class WiiSocket extends Socket {
  import flash.events.*;

  public var wiiStatus:String;

  private var buffer:String;

  public function WiiSocket() {
    addEventListener(Event.CONNECT, socketConnected);
    addEventListener(ProgressEvent.SOCKET_DATA, dataSent);
    buffer = '';
  }

  private function dataSent(e:ProgressEvent):void {
    buffer += readUTFBytes(e.bytesLoaded);
    var strings:Array = buffer.split("\n");
    if (strings.length == 1) {
      buffer = strings[0];
    } else {
      var l:Number = strings.length - 1;
      buffer = strings[l];
      wiiStatus = strings[l-1];
    }
  }

  private function socketConnected(a:Event):void {
    writeByte(0);
  }
}
