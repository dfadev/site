package site.net;

import haxe.io.Bytes;
import haxe.io.BytesOutput;

#if nodejs
import js.node.net.Socket;
import js.node.Buffer;
#end

class BackEnd {
	static public var connections:Array<BackEnd> = new Array<BackEnd>();
	static public function use(appservers:Array<{ host:String, port:Int }>) {
		for (appsrv in appservers) {
			var srv = new BackEnd(appsrv.host, Std.int(appsrv.port));
			connections.push(srv);
			srv.connect();
		}
	}

	var socket:Socket;
	var host:String;
	var port:Int;
	var bytesLength:Int;

	function new(host, port) {
		this.host = host;
		this.port = port;
	}

	function connect() {
		socket = new Socket();
		socket.setNoDelay(true);

		var cnx = new TcpConnection();
		var newb:Bytes = Bytes.alloc(TcpConnection.maxMessageSize + 4);
		var leftOver:Bytes = Bytes.alloc(TcpConnection.maxMessageSize + 4);
		var leftOverLength:Int = 0;

		socket.on(SocketEvent.Data, function(data:Buffer) {
			var bytes = data.hxToBytes();
			if (leftOver != null) {
				if (leftOverLength > 0) newb.blit(0, leftOver, 0, leftOverLength);
				bytesLength = bytes.length;
				newb.blit(leftOverLength, bytes, 0, bytesLength);
				bytesLength += leftOverLength;
				bytes = newb;
				leftOverLength = 0;
			}

			var rslt = cnx.readClientMessage(bytes, 0, bytesLength);
			if (cnx.error) {
				socket.destroy();
				return;
			}
			if (rslt.bytes != bytesLength) {
				leftOver.blit(0, bytes, bytesLength - rslt.bytes, rslt.bytes);
				leftOverLength = rslt.bytes;
			}

			if (rslt.msg != null) 
				for (m in rslt.msg) 
					Evt.handleMessage(m, true);
		});

		socket.on(SocketEvent.End, function() {
			trace('socket end');
			Evt.emit(ServerDisconnected(this));
		});

		socket.on(SocketEvent.Error, function (err) Evt.emit(Error(err)));

		socket.on("connect", function() Evt.emit(ServerConnected(this)));

		socket.on("close", function() haxe.Timer.delay(function() { socket.connect({ host: host, port: port }); }, 2500));

		socket.connect({ host: host, port: port });
	}

	public static function send(?id:Int = -1, msg) {
		try {
      var tcp = null;
      if (id == -1) {
        tcp = connections[id];
      } else {
        for (i in 0...connections.length) {
          tcp = connections[i];
          if (tcp != null) break;
        }
      }

			if (tcp == null) {
				Evt.emit(Error('BackEnd not connected, ${connections.length}'));
				return;
			}
			tcp.socket.write(Evt.asBuffer(msg, true));
		}
		catch (e:Dynamic) {
			Evt.emit(Error(e));
		}
	}
}
