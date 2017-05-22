import site.*;
using haxe.EnumTools;

enum Action {
	Event(msg:SiteMessage<NetworkMessage>);
}

enum NetworkMessage {
	Hello(world:String);
}

// stub to force generation of NetworkMessage serializer
@:keep class NetworkMessageStub implements hxbit.Serializable { @:s public var n:NetworkMessage; }

class Message {

#if browser
	static var hasConnectedOnce = false;
	public static function handler(action:Action) {
		switch (action) {
			case Event(msg):
				switch (msg) {
					case Connected(websocket):
						trace('client websocket connected');
						if (hasConnectedOnce)
							js.Browser.document.location.reload();
						hasConnectedOnce = true;

					case Disconnected(websocket):
						trace('client websocket disconnected');

					case Error(e):
						trace('client error:');
						trace(e);

					case DataMessage(srcId, destId, msg):
						switch (msg) {
							case Hello(msg):
								trace('Hello($msg)');
								WebSocketClient.send(NetworkMessage.Hello("from browser"));
							default:
								trace('unhandled message:');
								trace(msg);
						}
					default:
				}
			default:
		}
	}
#elseif webserver
	public static function handler(action:Action) {
		switch (action) {
			case Event(msg):
				switch (msg) {
					case Connected(socket):
						trace('client connected ${socket.id}');
						WebSocketServer.send(socket.id, NetworkMessage.Hello("from webserver"));

					case Disconnected(socket):
						trace('Disconnected ${socket.id}');

					case ServerConnected(proxy):
						trace('ServerConnected');
						proxy.send(NetworkMessage.Hello("from webserver to server"));

					case ServerDisconnected(proxy):
						trace('ServerDisconnected');

					case DataMessage(srcId, destId, msg):
						switch (msg) {
							case Hello(msg):
								trace('Hello($msg)');
							default:
								trace('unhandled message ${msg.getName()}');
						}

					case Error(e):
						Sys.println(e);


					default:
						trace('unhandled appmsg ${msg.getName()}');
				}

			default:
				trace('unhandled action: $action');
		}
	}
#elseif appserver
	public static function handler(action:Action) {
		switch (action) {
			case Event(msg):
				switch (msg) {
					case Connected(proxy):
						Sys.println('webserver connected');
						proxy.send(NetworkMessage.Hello('from appserver to webserver'));
					case Disconnected(proxy):
						Sys.println('webserver disconnected');
					case DataMessage(srcId, destId, msg):
						switch (msg) {
							case Hello(msg):
								Sys.println('Hello($msg)');
							default:
								Sys.println('unhandled message ${msg.getName()}');
						}

					case Error(e):
						Sys.println(e);
					default:
						Sys.println('* appsrv unhandled appmsg: ${msg.getName()}');
				}
			default:
				Sys.print('* appsrv unhandled msg: ');
				Sys.println(action);
		}
	}

#end
}


