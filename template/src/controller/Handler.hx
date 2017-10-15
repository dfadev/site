package controller;

import site.*;
import site.net.*;
import site.view.*;
import model.Action;
import model.NetworkMessage;

using haxe.EnumTools;

class Handler {

#if browser
	static var hasConnectedOnce = false;
	static var browserHello = NetworkMessage.Hello("from browser");

	public static function handle(action:Action) {
		switch (action) {
			case NetworkEvent(msg):
#if site_websocket
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
								WebSocketClient.send(browserHello);
							default:
								trace('unhandled message:');
								trace(msg);
						}

					case Starting:
						trace('view starting');

					case Started:
						trace('view started');

					default:
						trace('unhandled message:');
						trace(msg);
				}
#end
			default:
				trace('unhandled action: $action');
		}
	}
#elseif webserver
	static var webserverHello = NetworkMessage.Hello("from webserver");
	static var webserverToServerHello = NetworkMessage.Hello("from webserver to server");
	public static function handle(action:Action) {
		switch (action) {
			case NetworkEvent(msg):
				switch (msg) {
					case Connected(socket):
						Sys.println('websocket client connected ${socket.id}');
						WebSocketServer.send(socket.id, webserverHello);

					case Disconnected(socket):
						Sys.println('websocket client disconnected ${socket.id}');

					case ServerConnected(proxy):
						Sys.println('webserver connected to appserver');
						proxy.send(webserverToServerHello);

					case ServerDisconnected(proxy):
						Sys.println('webserver disconnected from appserver');

					case DataMessage(srcId, destId, msg):
						switch (msg) {
							case Hello(msg):
								Sys.println('Hello($msg)');
							default:
								Sys.println('unhandled message ${msg.getName()}');
						}

					case Starting:
						Sys.println('webserver starting');

					case Started:
						Sys.println('webserver started');

					case Error(e):
						Sys.println(e.toString());

					default:
						Sys.println('unhandled appmsg ${msg.getName()}');
				}

			default:
				trace('unhandled action: $action');
		}
	}
#elseif appserver
	static var appserverHello = NetworkMessage.Hello("from appserver to webserver");
	public static function handle(action:Action) {
		switch (action) {
			case NetworkEvent(msg):
				switch (msg) {
					case Connected(proxy):
						Sys.println('appserver connection accepted');
						proxy.send(appserverHello); //NetworkMessage.Hello('from appserver to webserver'));

					case Disconnected(proxy):
						Sys.println('appserver connection disconnected');

					case DataMessage(srcId, destId, msg):
						switch (msg) {
							case Hello(msg):
								Sys.println('Hello($msg)');
							default:
								Sys.println('unhandled message ${msg.getName()}');
						}

					case Starting:
						Sys.println('appserver starting');

					case Started:
						Sys.println('appserver started');

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
#elseif renderview
	public static function handle(action:Action) {
	}
#end
}


